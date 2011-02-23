class Faq < ActiveRecord::Base
  has_many :faq_details
  has_many :faq_votes  # faqs which more often answer people's questions should rise to the top. both because they're common, and because they may indicate a design review is necessary
  has_many :faq_details  # like comments, except non-threaded and with extra attributes
  has_many :faq_notifications  # a bunch of email addresses for update notifications
  has_many :support_tickets # tickets which were answered by this faq

  ### VALIDATIONS and CALLBACKS

  # only support volunteers can create faqs. positions monitonically increase, but can be overwritten
  before_validation(:on => :create) do
    raise_unless_volunteer
    self.position = (Faq.count + 1) unless self.position
  end

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  # must have content
  validates_presence_of :content

  attr_accessor :turn_off_notifications
  # add a default set of watchers to new tickets
  # TODO at the moment, this is just the person who created it
  after_create :add_default_watchers
  def add_default_watchers
    # on create, add owner to the notifications unless indicated otherwise
    self.watch! unless turn_off_notifications == "1"

    # TODO make default groups. e.g. support, that people can add and remove themselves to
    # so that when faqs are created the notifications are populated with these groups.
    # when someone is added to that group, add them to all tickets
    # this allows people to remove themselves from individual tickets if they usually watch all
    # and add themselves to individual tickets if they usually don't watch all
    self.send_create_notifications
  end

  ### HELPER METHODS

  def vote_count
    faq_votes.sum(:vote)
  end

  def mail_to(private = false)
    notifications = self.faq_notifications
    notifications = notifications.official if private
    notifications.map(&:email).uniq
  end

  # returns the support ticket with the given code
  # a guest of any ticket can leave comments on and watch any faq
  def associated_ticket(code)
    SupportTicket.where(:authentication_code => code).first
  end

  # used in view to determine whether to offer to turn on or off notifications
  # need to return false if
  def watched?(code = nil)
    raise_unless_logged_in_or_guest(code)
    email_address = User.current_user ? User.current_user.email : self.associated_ticket(code).email
    # if there's no watcher with that email, this will be nil which acts as false
    self.faq_notifications.where(:email => email_address).first
  end

  # okay until we need to paginate
  # sort by votes
  def <=>(other)
    other.vote_count <=> self.vote_count
  end

  # WORKFLOW / STATE MACHINE

  include Workflow
  workflow_column :status

  workflow do
    state :rfc do
      event :post, :transitions_to => :faq
    end
    state :faq do
      event :open_for_comments, :transitions_to => :rfc
    end

    on_transition do |from, to, triggering_event, *event_args|
      next if self.new_record?
      halt! unless User.current_user.support_volunteer?
      content = "#{from} -> #{to}"
      content += " (#{event_args.first})" unless event_args.blank?
      self.faq_details.create(:content => content,
                               :support_identity_id => User.current_user.support_identity_id,
                               :support_response => true,
                               :system_log => true)
    end
    after_transition do |from, to, triggering_event, *event_args|
      self.send_update_notifications
    end
  end

  ### SCOPES and ARRAYS

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  default_scope :order => 'position ASC'

  ### WORKFLOW methods (call with ! to change state)
  # volunteer status is checked by workflow on_transition
  # logs system_log details via workflow on_transition
  # sends notifications via workflow on_transition
  # some methods add you as watcher, some don't. some change owner, some don't

  def post
    raise_unless_admin
  end

  def open_for_comments(reason)
    raise_unless_volunteer
  end

  ### NON-WORKFLOW but similar methods.
  # call mailers directly to get notifications.
  # call log! directly to add transitions to details
  # check volunteer status directly when necessary

  def update_from_edit!(position, summary, content)
    raise_unless_volunteer
    self.position = position
    self.summary = summary
    self.content = content
    self.save!
    self.faq_details.create(:content => "faq edited",
                            :support_identity_id => User.current_user.support_identity_id,
                            :support_response => true,
                            :system_log => true)
    self.send_update_notifications
  end

  # only logged in users or guest owners can comment
  def comment!(content, response=nil, code=nil)
    return if content.blank?
    raise "not open for comments" unless self.rfc?
    raise_unless_logged_in_or_guest(code)
    support_response = false
    private_response = false
    if code
      response = "unofficial"
    elsif response.nil?
      response = User.current_user.support_volunteer? ? "official" : "unofficial"
    end
    case response
    when "official"
      raise_unless_volunteer
      support_response = true
    when "private"
      raise_unless_volunteer
      private_response = true
      support_response = true
    end
    detail = self.faq_details.create!(:content => content,
                            :support_identity_id => User.current_user.try(:support_identity).try(:id),
                            :support_response => support_response,
                            :system_log => false,
                            :private => private_response)
    self.send_update_notifications(private_response)
    return detail
  end

  # anyone can vote, and can vote multiple times, but not on a draft
  def vote!
    raise "can't vote until posted" if self.rfc?
    FaqVote.create(:faq_id => self.id)
  end

  def watch!(code = nil)
    return true if watched?(code)
    raise_unless_logged_in_or_guest(code)
    email_address = User.current_user ? User.current_user.email : self.associated_ticket(code).email
    self.faq_notifications.create(:email => email_address)
  end

  def unwatch!(code = nil)
    raise "Couldn't remove watch. Not watching." unless watched?(code)
    raise_unless_logged_in_or_guest(code)
    email_address = User.current_user ? User.current_user.email : self.associated_ticket(code).email
    self.faq_notifications.where(:email => email_address).delete_all
  end

  ### SEND NOTIFICATIONS

  def send_create_notifications
    self.mail_to.each do |recipient|
      FaqMailer.create_notification(self, recipient).deliver
    end
  end
  def send_update_notifications(private = false)
    self.mail_to(private).each do |recipient|
      FaqMailer.update_notification(self, recipient).deliver
    end
  end

  # SANITIZER stuff
  attr_protected :summary_sanitizer_version
  def sanitized_summary
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :summary
    summary.html_safe
  end

  attr_protected :content_sanitizer_version
  def sanitized_content
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :content
    content.html_safe
  end

  ### a bunch of methods which raise SecurityError

  def raise_unless_logged_in
    raise SecurityError, "not logged in!" unless User.current_user
  end

  # returns the ticket which gives authentication
  def raise_unless_guest(code)
    raise SecurityError, "can't check guest if logged in!" if User.current_user
    associated_ticket(code) || raise(SecurityError, "no associated security tickets")
  end

  def raise_unless_logged_in_or_guest(code=nil)
    code.blank? ? raise_unless_logged_in : raise_unless_guest(code)
  end

  def raise_unless_volunteer
    raise_unless_logged_in
    raise SecurityError, "not a support volunteer!" unless User.current_user.support_volunteer?
  end

  def raise_unless_admin
    raise_unless_logged_in
    raise SecurityError, "not a support admin!" unless User.current_user.support_admin?
  end

end
