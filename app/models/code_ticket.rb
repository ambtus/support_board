class CodeTicket < ActiveRecord::Base

  belongs_to :pseud  # the pseud of the user who is working on the ticket
  belongs_to :admin_post # after it's fixed
  belongs_to :code_ticket # for dupes
  has_many :code_votes # for prioritizing (lots of votes = high priority)
  has_many :code_notifications  # a bunch of email addresses for update notifications
  has_many :code_details  # like comments, except non-threaded and with extra attributes
  has_many :support_tickets

  # don't save new empty details
  accepts_nested_attributes_for :code_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  # used in lists
  def name
    "Code Ticket #" + self.id.to_s
  end

  # STATUS/RESOLUTION stuff

  def status_line
    if self.pseud
      if self.code_ticket_id
        "Closed as dupe"
      elsif self.deployed_rev
        "Fixed and deployed"
      elsif self.committed_rev
        "Fixed"
      else
        "In progress"
      end
    else
      "Open"
    end
  end

  attr_accessor :updated_resolved

  # code tickets can be closed as dupes or closed by committing a code fix
  after_save :update_resolved
  def update_resolved
    Rails.logger.debug "running update_resolved after code ticket save"
    return if updated_resolved # already updated, don't check and save again
    old = self.resolved
    # for some very strange reason, updating 0 with 0 makes rails think the attribute
    # is dirty, and it's acting as if it had changed.
    self.resolved = self.code_ticket_id? || self.committed_rev?
    self.updated_resolved = true # set attr_accessor so don't trigger infinite loop
    new = self.resolved
    self.save unless old == new
    true
  end

  # VOTES
  attr_accessor :vote_up

  # run from controller after update (only logged in users are offered the choice)
  def update_votes(current_user)
    # are they already voting?
    vote = self.code_votes.where(:user_id => current_user.id).first
    # if they are, and they want to stop, remove the vote
    vote.destroy if (vote && self.vote_up == "0")
    # if they aren't, and they want to, add a vote.
    if !vote && self.vote_up == "1"
      self.code_votes.create(:user => current_user, :vote => 1)
    end
  end

  def vote_count
    code_votes.sum(:vote)
  end

  # NOTIFICATION stuff

  attr_accessor :turn_off_notifications
  attr_accessor :turn_on_notifications
  attr_accessor :send_notifications

  # run from controller after update (only logged in users are offered the choice)
  def update_watchers(current_user)
    # are they already watching?
    watcher = self.code_notifications.where(:email => current_user.email).first
    # if they are, and they want to stop, remove the watcher
    watcher.destroy if (watcher && self.turn_off_notifications == "1")
    # if they aren't, and they want to start, add a watcher.
    if !watcher && self.turn_on_notifications == "1"
      self.code_notifications.create(:email => current_user.email)
    end
  end

  def mail_to
    self.code_notifications.map(&:email).uniq
  end

  # used in view to determine whether to offer to turn on or off notifications
  def being_watched?(current_user)
    self.code_notifications.where(:email => current_user.email).first
  end

  before_save :check_if_changed
  def check_if_changed
    self.send_notifications = true if self.changed?
    self.send_notifications = true if !self.code_details.select{|d| d.changed?}.empty?
    true
  end

  # situations where notifications should not be sent
  def skip_notifications?
    # skip the notification if neither the code ticket nor any of its details have changed, just the watchers
    # set in check_if_changed before save. will only trigger if you use self.code_details.build && self.save
    # if you update the code_details without going through the master ticket, this will not trigger!
    return true unless self.send_notifications

    # don't try to send email if there's no-one to send it to
    return true if self.code_notifications.count < 1

    false
  end

  def send_create_notifications
    unless self.skip_notifications?
      self.mail_to.each do |recipient|
        CodeTicketMailer.create_notification(self, recipient).deliver
      end
    end
  end

  def send_update_notifications
    unless self.skip_notifications?
      self.mail_to.each do |recipient|
        CodeTicketMailer.update_notification(self, recipient).deliver
      end
    end
  end

  # SANITIZER stuff

  attr_protected :summary_sanitizer_version
  def sanitized_summary
    sanitize_field self, :summary
  end

end
