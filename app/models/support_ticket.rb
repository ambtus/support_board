class SupportTicket < ActiveRecord::Base

  belongs_to :user   # the user who opened the ticket
  belongs_to :pseud  # the pseud of the user who is working on the ticket
  belongs_to :archive_faq  # for 'Question' tickets
  belongs_to :code_ticket  # for 'Problem' and 'Suggestion' tickets. automatic +1 vote
  has_many :support_watchers  # a bunch of email addresses for update notifications
  has_many :support_details  # like comments, except non-threaded and with extra attributes

  # don't save new empty details
  accepts_nested_attributes_for :support_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  # must have valid email unless logged in
  validates :email, :email_veracity => {:on => :create, :unless => :user_id}

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  # used in lists
  def name
    "Support Ticket #" + self.id.to_s
  end

  # RESOLUTION stuff

  # scope
  def self.open
    where(:owner_resolved => 0).where(:support_resolved => false)
  end

  def resolved?
    self.owner_resolved? || self.support_resolved?
  end

  # support tickets can be user resolved (the user accepts one or more answers)
  # or support resolved (the support person has linked to a FAQ or a ticket, or handed it off to an admin
  before_save :update_resolved
  def update_resolved
    self.owner_resolved = self.support_details.resolved.count
    # if there are no details which have been marked "resolved_ticket" the count will be 0
    # and owner_resolved? will return false,
    # otherwise it will be a positive number, and owner_resolved? will return true

    self.support_resolved = self.archive_faq || self.code_ticket || self.category == "Admin"
    # if there are no links, or it hasn't been handed of to admins then support_resolved? will be false
    # otherwise it will be true

    true
  end

  # NOTIFICATION stuff

  attr_accessor :turn_off_notifications
  attr_accessor :turn_on_notifications
  attr_accessor :send_notifications

  after_create :add_owner_as_watcher
  def add_owner_as_watcher
    # unless they've asked you not too
    return true if turn_off_notifications == "1"
    # otherwise, add the email supplied in the ticket, or the email of the user who opened it
    self.support_watchers.create(:email => self.email || self.user.email)
  end

  # run from controller after update
  def update_watchers(current_user)
    # take care of the current user's wishes re notification
    # the email of the user editing the ticket. if there is no current_user, it must be the guest owner
    email_address = current_user ? current_user.email : self.email
    # are they already watching?
    watcher = self.support_watchers.where(:email => email_address).first
    # if they are, and they want to stop, remove the watcher
    watcher.destroy if (watcher && self.turn_off_notifications == "1")
    # if they aren't, and they want to start, add a watcher.
    if !watcher && self.turn_on_notifications == "1"
      # mark the watcher as a public watcher if not the owner or a support volunteer
      public = true
      public = !current_user.try(:is_support_volunteer?) # support volunteers
      public = false if self.email # guest owners
      public = false if self.user && self.user == current_user # user owner
      self.support_watchers.create(:email => email_address, :public_watcher => public)
    end

    # if the ticket has been made private remove all watchers who aren't support volunteers or owners
    self.support_watchers.where(:public_watcher => true).delete_all if self.private?
  end

  def mail_to
    self.support_watchers.map(&:email).uniq
  end

  # used in view to determine whether to offer to turn on or off notifications
  def being_watched?(current_user)
    # the email of the user viewing the ticket.
    # if there is no current_user, it must be the guest owner
    # because other non-logged-in users aren't offered the choice
    email_address = current_user ? current_user.email : self.email
    # if there's no watcher with that email, this will be nil which acts as false
    self.support_watchers.where(:email => email_address).first
  end

  before_save :check_if_changed
  def check_if_changed
    self.send_notifications = true if self.changed?
    self.send_notifications = true if !self.support_details.select{|d| d.changed?}.empty?
    true
  end

  # situations where notifications should not be sent
  def skip_notifications?
    # skip the notification if neither the support ticket nor any of its details have changed, just the watchers
    # set in check_if_changed before save. will only trigger if you use self.support_details.build && self.save
    # if you update the support_details without going through the master ticket, this will not trigger!
    return true unless self.send_notifications

    # don't try to send email if there's no-one to send it to
    return true if self.support_watchers.count < 1

    false
  end

  def send_create_notifications
    unless self.skip_notifications?
      self.mail_to.each do |recipient|
        SupportTicketMailer.create_notification(self, recipient).deliver
      end
    end
  end

  def send_update_notifications
    unless self.skip_notifications?
      self.mail_to.each do |recipient|
        SupportTicketMailer.update_notification(self, recipient).deliver
      end
    end
  end

  # AUTHENTICATION stuff

  before_create :create_authentication_code
  def create_authentication_code
    if self.email
      self.authentication_code = SecureRandom.hex(10)
    end
  end

  def owner?(code, current_user)
    if !current_user # not logged in
      return false if self.authentication_code.blank? # not a guest ticket
      code == self.authentication_code # does ticket authentication match authentication code?
    else # logged in
      current_user.id == self.user_id  # does ticket owner match current user?
    end
  end

  # SPAM stuff
  attr_protected :approved

  validate :check_for_spam
  def check_for_spam
    errors.add(:base, "^This ticket looks like spam to our system, sorry! Please try again, or create an account to submit.") unless check_for_spam?
  end

  def check_for_spam?
    # don't check for spam while running tests or if logged in
    self.approved = Rails.env.test? || self.user_id || !Akismetor.spam?(akismet_attributes)
  end

  def mark_as_spam!
    update_attribute(:approved, false)
    Akismetor.submit_spam(akismet_attributes)
  end

  def mark_as_ham!
    update_attribute(:approved, true)
    #Akismetor.submit_ham(akismet_attributes)
  end

  def akismet_attributes
    {
      :user_ip => ip_address,
      :user_agent => user_agent,
      :comment_author_email => email,
      :comment_content => summary
    }
  end

  # SANITIZER stuff

  attr_protected :summary_sanitizer_version
  def sanitized_summary
    sanitize_field self, :summary
  end

end
