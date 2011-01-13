class Faq < ActiveRecord::Base
  has_many :faq_details
  has_many :faq_votes  # faqs which more often answer people's questions should rise to the top. both because they're common, and because they may indicate a design review is necessary
  has_many :faq_details  # like comments, except non-threaded and with extra attributes
  has_many :faq_notifications  # a bunch of email addresses for update notifications
  belongs_to :support_identity # the support identity of the last user to work on the faq
  has_many :support_tickets # tickets which were answered by this faq

  # don't save new empty details
  accepts_nested_attributes_for :faq_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  default_scope :order => 'position ASC'

  def vote_count
    faq_votes.sum(:vote)
  end

  # okay until we need to paginate
  def self.sort_by_vote
    self.all.sort{|f1,f2|f2.vote_count <=> f1.vote_count}
  end

  before_create :set_owner
  def set_owner
    raise "Couldn't create. Not logged in." unless User.current_user
    raise "Couldn't post. Not logged in as support volunteer." unless User.current_user.support_volunteer?
    self.support_identity_id = User.current_user.support_identity_id
  end

  before_create :set_position
  def set_position
    self.position = Faq.count + 1 unless self.position
  end

  # FAQ DETAILS stuff
  # only logged in users or guest owners can comment
  def comment!(content, official=true, authentication_code=nil)
    raise "not open for comments" unless self.rfc?
    if !User.current_user
      raise "Couldn't comment. not logged in and not guest owner!" unless guest_owner?(authentication_code)
    elsif User.current_user.nil?
      raise "Couldn't comment. Not logged in."
    end
    support_response = (official && User.current_user.support_volunteer?)
    self.faq_details.create(:content => content,
                            :support_identity_id => User.current_user.try(:support_identity).try(:id),
                            :support_response => support_response,
                            :system_log => false)
    self.send_update_notifications
  end

  # are any of the associated support tickets owned by the current user?
  def guest_owner?(authentication_code)
    return false unless authentication_code
    raise "shouldn't have authentication code if logged in" if User.current_user
    self.support_tickets.where(:authentication_code => authentication_code).first
  end

  # STATUS/RESOLUTION stuff
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
      self.send_update_notifications
    end
  end

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  def post
    raise "Couldn't post. Not logged in." unless User.current_user
    raise "Couldn't post. Not logged in as support admin." unless User.current_user.support_admin?
    self.support_identity_id = User.current_user.support_identity_id
  end

  def open_for_comments(reason)
    raise "Couldn't reopen. Not logged in." unless User.current_user
    raise "Couldn't reopen. Not logged in as support volunteer." unless User.current_user.support_volunteer?
    self.support_identity_id = User.current_user.support_identity_id
  end

  def vote!
    FaqVote.create(:faq_id => self.id)
  end

  def update_from_edit!(position, title, content)
    raise "Couldn't update. Not logged in." unless User.current_user
    raise "Couldn't update. Not support volunteer." unless User.current_user.support_volunteer?
    self.position = position
    self.title = title
    self.content = content
    self.support_identity_id = User.current_user.support_identity_id
    self.save!
    self.faq_details.create(:content => "faq edited",
                            :support_identity_id => User.current_user.support_identity_id,
                            :support_response => true,
                            :system_log => true)
    self.send_update_notifications
  end

  # NOTIFICATION stuff
  def mail_to
    self.faq_notifications.map(&:email).uniq
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

  def watch!(authentication_code = nil)
    if authentication_code
      email_address = SupportTicket.find_by_authentication_code(authentication_code).try(:email)
    else
      raise "Couldn't watch. Not logged in." unless User.current_user
      email_address = User.current_user.email
      # create a support identity for tracking purposes
      User.current_user.support_identity unless User.current_user.support_identity_id
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
      # create a support identity for tracking purposes
      User.current_user.support_identity unless User.current_user.support_identity_id
    end
    raise "Couldn't watch. No email address to watch with." unless email_address
    raise "Couldn't remove watch. Not watching." unless watched?(authentication_code)
    self.faq_notifications.where(:email => email_address).delete_all
  end

  def send_update_notifications
    self.mail_to.each do |recipient|
      FaqMailer.update_notification(self, recipient).deliver
    end
  end

end
