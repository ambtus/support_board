class CodeTicket < ActiveRecord::Base

  belongs_to :support_identity # the support identity of the last user to work on the ticket
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

  # CodeTicket methods
  def self.stage!(revision)
    raise "Couldn't stage. Not logged in." unless User.current_user
    raise "Couldn't stage. Not logged in as support admin." unless User.current_user.support_admin?
    CodeTicket.committed.where("revision <= ?", revision).each {|ct| ct.stage!(revision)}
  end

  def self.deploy!
    raise "Couldn't deploy. Not logged in." unless User.current_user
    raise "Couldn't deploy. Not logged in as support admin." unless User.current_user.support_admin?
    revision = SupportBoard::REVISION_NUMBER
    CodeTicket.verified.where("revision <= ?", revision).each {|ct| ct.deploy!(revision)}
    SupportTicket.waiting.where("revision <= ?", revision).each {|st| st.deploy!(revision)}
  end

  # used in lists
  def name
    "Code Ticket #" + self.id.to_s
  end

  # STATUS/RESOLUTION stuff
  include Workflow
  workflow_column :status

  def status_line
    if self.code_ticket_id
      "closed as duplicate by #{self.support_identity.name}"
    elsif self.unowned?
      "open"
    else
      "#{self.status} by #{self.support_identity.name}"
    end
  end

  workflow do
    state :unowned do
      event :take, :transitions_to => :taken
      event :duplicate, :transitions_to => :closed
      event :commit, :transitions_to => :committed
      event :reject, :transitions_to => :closed
    end
    state :taken do
      event :commit, :transitions_to => :committed
      event :duplicate, :transitions_to => :closed
      event :reject, :transitions_to => :closed
      event :steal, :transitions_to => :taken
      event :reopen, :transitions_to => :unowned
    end
    state :committed do
      event :stage, :transitions_to => :staged
      event :reopen, :transitions_to => :unowned
    end
    state :staged do
      event :verify, :transitions_to => :verified
      event :reopen, :transitions_to => :unowned
    end
    state :verified do
      event :deploy, :transitions_to => :closed
      event :reopen, :transitions_to => :unowned
    end
    state :closed do
      event :reopen, :transitions_to => :unowned
    end

    on_transition do |from, to, triggering_event, *event_args|
      halt! unless User.current_user.support_volunteer?
      content = "#{from} -> #{to}"
      content += " (#{event_args.first})" unless event_args.blank?
      self.code_details.create(:content => content,
                               :support_identity_id => User.current_user.support_identity_id,
                               :support_response => true,
                               :system_log => true)
      self.send_update_notifications unless [:steal].include?(triggering_event)
    end
  end

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  def self.not_closed
    where('status != "closed"')
  end

  def take
    self.support_identity_id = User.current_user.support_identity_id
    self.watch! unless self.watched?
  end

  def not_mine?
    raise "Couldn't check ownership. Not logged in." unless User.current_user
    self.support_identity_id != User.current_user.support_identity_id
  end

  def duplicate(dupe_id)
    raise "Couldn't duplicate: no code ticket with id: #{dupe_id}" unless CodeTicket.find_by_id(id)
    self.code_ticket_id = dupe_id
    self.support_identity_id = User.current_user.support_identity_id
  end

  def steal
    self.send_steal_notification(User.current_user)
    self.support_identity_id = User.current_user.support_identity_id
  end

  def reject(reason)
    raise "Couldn't reject. No reason given." if reason.blank?
    self.support_identity_id = User.current_user.support_identity_id
  end

  def reopen(reason)
    raise "Couldn't reopen. No reason given." if reason.blank?
    self.code_ticket_id = nil
    self.revision = nil
    self.support_identity_id = nil
  end

  def commit(revision)
    raise "Couldn't commit. No revision given." if revision.blank?
    self.revision = revision
    self.support_identity_id = User.current_user.support_identity_id
  end

  def stage(revision)
    raise "Couldn't stage. No revision given." if revision.blank?
    self.revision = revision
    self.support_identity_id = User.current_user.support_identity_id
  end

  def verify(revision)
    raise "Couldn't verify. No revision given." if revision.blank?
    self.revision = revision
    self.support_identity_id = User.current_user.support_identity_id
  end

  def deploy(revision)
    raise "Couldn't deploy. No revision given." if revision.blank?
    self.revision = revision
    self.support_tickets.each {|st| st.update_attribute(:revision, revision) }
    self.support_identity_id = User.current_user.support_identity_id
  end

  # VOTES
  # only logged in users can vote for code tickets

  def voted?
    raise "Couldn't check vote. Not logged in." unless User.current_user
    self.code_votes.where(:user_id => User.current_user.id).first
  end

  def vote!(count = 1)
    raise "Couldn't vote. Not logged in." unless User.current_user
    raise "already voted" if voted?
    self.code_votes.create(:user => User.current_user, :vote => count)
  end

  def vote_count
    code_votes.sum(:vote)
  end

  # okay until we need to paginate
  def self.sort_by_vote
    self.all.sort{|f1,f2|f2.vote_count <=> f1.vote_count}
  end

  def update_from_edit!(summary, description, url, browser)
    raise "Couldn't update. Not logged in." unless User.current_user
    raise "Couldn't update. Not support volunteer." unless User.current_user.support_volunteer?
    self.summary = summary
    self.description = description unless description.blank?
    self.url = url unless url.blank?
    self.browser = browser unless browser.blank?
    self.support_identity_id = User.current_user.support_identity_id
    self.save!
    self.code_details.create(:content => "ticket edited",
                             :support_identity_id => User.current_user.support_identity_id,
                             :support_response => true,
                             :system_log => true)
    self.send_update_notifications
  end

  # CODE DETAILS stuff
  # only logged in users can comment
  # only support volunteers can comment on non-open tickets
  def comment!(content, official=true)
    raise "Couldn't comment. Not logged in." unless User.current_user
    support_response = (official && User.current_user.support_volunteer?)
    if self.unowned? || support_response
      self.code_details.create(:content => content,
                               :support_identity_id => User.current_user.support_identity.id,
                               :support_response => support_response,
                               :system_log => false)
      self.send_update_notifications
    else
      raise "Couldn't comment. Only official comments allowed."
    end
  end

  # NOTIFICATION stuff
  # only logged in users can watch code tickets

  def watched?
    raise "Couldn't check watch status. Not logged in." unless User.current_user
    self.code_notifications.where(:email => User.current_user.email).first
  end

  def watch!
    raise "Couldn't watch. Not logged in." unless User.current_user
    raise "Couldn't watch. Already watching." if watched?
    # create a support identity for tracking purposes
    User.current_user.support_identity unless User.current_user.support_identity_id
    self.code_notifications.create(:email => User.current_user.email)
  end

  def unwatch!
    raise "Couldn't remove watch. Not watching." unless watched?
    self.code_notifications.where(:email => User.current_user.email).destroy_all
  end

  # returns an array of email addresses. [] if none
  def mail_to
    self.code_notifications.map(&:email).uniq
  end

  def send_create_notifications
    self.mail_to.each do |recipient|
      CodeTicketMailer.create_notification(self, recipient).deliver
    end
  end

  def send_update_notifications
    self.mail_to.each do |recipient|
      CodeTicketMailer.update_notification(self, recipient).deliver
    end
  end

  def send_steal_notification(stealer)
    CodeTicketMailer.steal_notification(self, stealer).deliver
  end

  # SANITIZER stuff

  attr_protected :summary_sanitizer_version, :description_sanitizer_version
  def sanitized_summary
    sanitize_field self, :summary
  end
  def sanitized_description
    sanitize_field self, :description
  end

end
