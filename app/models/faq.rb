class Faq < ActiveRecord::Base
  has_many :faq_details
  has_many :faq_votes  # faqs which more often answer people's questions should rise to the top. both because they're common, and because they may indicate a design review is necessary
  has_many :faq_details  # like comments, except non-threaded and with extra attributes
  has_many :faq_notifications  # a bunch of email addresses for update notifications
  has_many :support_tickets # tickets which were answered by this faq

  ### VALIDATIONS and CALLBACKS

  # only support volunteers can create faqs. positions monitonically increase, but can be overwritten
  before_validation(:on => :create) do
    raise SecurityError, "only volunteers can create code tickets" if !User.current_user.try(:support_volunteer?)
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
    self.watch! if turn_off_notifications.blank?

    # TODO make default groups. e.g. support, that people can add and remove themselves to
    # so that when faqs are created the notifications are populated with these groups.
    # when someone is added to that group, add them to all tickets
    # this allows people to remove themselves from individual tickets if they usually watch all
    # and add themselves to individual tickets if they usually don't watch all
  end

  ### HELPER METHODS

  # are any of the associated support tickets owned by the current user?
  def guest_owner?(authentication_code)
    return false unless authentication_code
    raise "shouldn't have authentication code if logged in" if User.current_user
    self.support_tickets.where(:authentication_code => authentication_code).first
  end

  def vote_count
    faq_votes.sum(:vote)
  end

  def mail_to(private = false)
    notifications = self.faq_notifications
    notifications = notifications.official if private
    notifications.map(&:email).uniq
  end

  # used in view to determine whether to offer to turn on or off notifications
  def watched?(authentication_code = nil)
    if !authentication_code.blank?
      email_address = SupportTicket.find_by_authentication_code(authentication_code).try(:email)
    else
      email_address = User.current_user.try(:email)
    end
    raise "Couldn't check watch. No email address to check." unless email_address
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
    raise "Couldn't post. Not logged in." unless User.current_user
    raise "Couldn't post. Not logged in as support admin." unless User.current_user.support_admin?
  end

  def open_for_comments(reason)
    raise "Couldn't reopen. Not logged in." unless User.current_user
    raise "Couldn't reopen. Not logged in as support volunteer." unless User.current_user.support_volunteer?
  end

  ### NON-WORKFLOW but similar methods.
  # call mailers directly to get notifications.
  # call log! directly to add transitions to details
  # check volunteer status directly when necessary

  def update_from_edit!(position, summary, content)
    raise "Couldn't update. Not logged in." unless User.current_user
    raise "Couldn't update. Not support volunteer." unless User.current_user.support_volunteer?
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
  def comment!(content, official=true, private = false, authentication_code=nil)
    raise "not open for comments" unless self.rfc?
    if !User.current_user
      raise "Couldn't comment. not logged in and not guest owner!" unless guest_owner?(authentication_code)
    elsif User.current_user.nil?
      raise "Couldn't comment. Not logged in."
    end
    support_response = (official && User.current_user.support_volunteer?)
    raise ArgumentError, "Only official comments can be private" if private && !support_response
    detail = self.faq_details.create!(:content => content,
                            :support_identity_id => User.current_user.try(:support_identity).try(:id),
                            :support_response => support_response,
                            :system_log => false,
                            :private => private)
    self.send_update_notifications(private)
    return detail
  end

  # anyone can vote, and can vote multiple times
  def vote!
    FaqVote.create(:faq_id => self.id)
  end

  def watch!(authentication_code = nil)
    if authentication_code
      email_address = SupportTicket.find_by_authentication_code(authentication_code).try(:email)
    else
      raise "Couldn't watch. Not logged in." unless User.current_user
      email_address = User.current_user.email
    end
    raise "Couldn't watch. No email address to watch with." unless email_address
    raise "Couldn't watch. Already watching." if watched?(authentication_code)
    self.faq_notifications.create(:email => email_address)
  end

  def unwatch!(authentication_code = nil)
    if authentication_code
      email_address = SupportTicket.find_by_authentication_code(authentication_code).try(:email)
    else
      raise "Couldn't watch. Not logged in." unless User.current_user
      email_address = User.current_user.email
    end
    raise "Couldn't watch. No email address to watch with." unless email_address
    raise "Couldn't remove watch. Not watching." unless watched?(authentication_code)
    self.faq_notifications.where(:email => email_address).delete_all
  end

  ### SEND NOTIFICATIONS

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

end
