class SupportTicket < ActiveRecord::Base

  belongs_to :user   # the user who opened the ticket (optional)
  belongs_to :support_identity  # the support_identity of the user who is working on the ticket
  belongs_to :faq  # for tickets closed by answering with a FAQ
  has_one :faq_vote # automatic votes when associated with a code ticket
  belongs_to :code_ticket  # for waiting tickets. closed when the code ticket is deployed
  has_one :code_vote # automatic votes when associated with a code ticket
  has_many :support_notifications  # a bunch of email addresses for update notifications
  has_many :support_details  # like comments, except non-threaded and with extra attributes

  # don't save new empty details
  accepts_nested_attributes_for :support_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  # must have valid email unless logged in
  validates :email, :email_veracity => {:on => :create, :unless => :user_id}

  before_create :guests_are_already_anonymous
  def guests_are_already_anonymous
    self.anonymous = false if self.email
    true
  end

  # used for tickets which were posted
  def post_name
    if self.email
      "A guest"
    elsif self.anonymous
      "A user"
    else
      self.user.login
    end
  end

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  # used in lists
  def name
    "Support Ticket #" + self.id.to_s
  end

  def self.ids
    select("support_tickets.id").map(&:id)
  end

  # filter support tickets
  def self.filter(params = {})
    tickets = SupportTicket.scoped

    # tickets opened by user
    if !params[:owned_by_user].blank?
      user = User.find_by_login(params[:owned_by_user])
      raise ActiveRecord::RecordNotFound unless user
      tickets = tickets.where(:user_id => user.id)
      # if not filtering by own name, rule out private tickets
      if User.current_user != user
        tickets = tickets.where(:anonymous => false)
      end
      # if not support volunteer or filtering by own name rule out private tickets
      if !(User.current_user.try(:support_volunteer?) || User.current_user == user)
        tickets = tickets.where(:private => false)
      end
    end

    # tickets I am watching, private
    if !params[:watching].blank?
      user = User.current_user
      raise SecurityError unless user
      tickets = tickets.joins(:support_notifications) & SupportNotification.where(:email => user.email)
    end

    # if you are filtering by user, the test for private tickets has already been done
    if params[:owned_by_user].blank? && params[:watching].blank?
      tickets = tickets.where(:private => false) unless User.current_user.try(:support_volunteer?)
    end

    # ticket's commented on by user
    if !params[:comments_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:comments_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      tickets = tickets.joins(:support_details) & SupportDetail.where(:system_log => false, :support_identity_id => support_identity.id)
    end

    # tickets owned by volunteer
    if !params[:owned_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:owned_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      tickets = tickets.where(:support_identity_id => support_identity.id)
    end

    # filter by status
    if !params[:status].blank?
      case params[:status]
      when "unowned"
        tickets = tickets.unowned
      when "taken"
        tickets = tickets.taken
      when "waiting_on_admin"
        tickets = tickets.waiting_on_admin
      when "posted"
        tickets = tickets.posted
      when "waiting"
        tickets = tickets.waiting
      when "spam"
        tickets = tickets.spam
      when "closed"
        tickets = tickets.closed
      when "all"
        # no op
      when "open"
        tickets = tickets.where('status != "closed"').where('status != "spam"').where('status != "posted"')
      else
        raise TypeError
      end
    else # default status is not closed (open)
      tickets = tickets.where('status != "closed"').where('status != "spam"').where('status != "posted"')
    end

    case params[:order_by]
    when "recent"
      tickets = tickets.order("updated_at desc")
    when "oldest"
      tickets = tickets.order("updated_at asc")
    when "earliest"
      tickets = tickets.order("id desc")
    else # "newest" by default
      tickets = tickets.order("id asc")
    end
    return tickets
  end

  # STATUS/RESOLUTION stuff
  include Workflow
  workflow_column :status

  def status_line
    if self.closed? && self.support_identity_id.nil?
      "closed by owner"
    elsif self.unowned?
      "open"
    elsif self.spam?
      "spam"
    elsif self.waiting?
      "waiting for a code fix"
    elsif self.waiting_on_admin?
      "waiting for an admin"
    elsif self.closed? && self.code_ticket_id
      "fixed in #{self.code_ticket.release_note.release}"
    else
      "#{self.status} by #{self.support_identity.name}"
    end
  end

  workflow do
    state :unowned do
      event :take, :transitions_to => :taken
      event :needs_fix, :transitions_to => :waiting
      event :post, :transitions_to => :posted
      event :answer, :transitions_to => :closed
      event :accept, :transitions_to => :closed
      event :spam, :transitions_to => :spam
      event :needs_admin, :transitions_to => :waiting_on_admin
      event :resolve, :transitions_to => :closed
    end
    state :taken do
      event :steal, :transitions_to => :taken
      event :reopen, :transitions_to => :unowned
      event :needs_fix, :transitions_to => :waiting
      event :post, :transitions_to => :posted
      event :answer, :transitions_to => :closed
      event :accept, :transitions_to => :closed
      event :needs_admin, :transitions_to => :waiting_on_admin
      event :resolve, :transitions_to => :closed
    end
    state :waiting do
      event :reopen, :transitions_to => :unowned
      event :deploy, :transitions_to => :closed
    end
    state :waiting_on_admin do
      event :reopen, :transitions_to => :unowned
      event :resolve, :transitions_to => :closed
    end
    state :posted do
      event :reopen, :transitions_to => :unowned
    end
    state :spam do
      event :ham, :transitions_to => :unowned
    end
    state :closed do
      event :reopen, :transitions_to => :unowned
    end

    on_transition do |from, to, triggering_event, *event_args|
      next if self.new_record?
      support_identity_id = User.current_user.try(:support_identity_id)
      official = User.current_user && User.current_user.support_volunteer?
      content = "#{from} -> #{to}"
      content += " (#{event_args.first})" unless event_args.blank?
      self.support_details.create(:content => content,
                               :support_identity_id => support_identity_id,
                               :support_response => official,
                               :system_log => true)
      self.send_update_notifications unless [:spam, :ham, :steal].include?(triggering_event)
    end
  end

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  def spam
    raise "Couldn't mark as spam, not logged in." unless User.current_user
    raise "Couldn't mark as spam, not a support volunteer." unless User.current_user.support_volunteer?
    # don't submit spam reports unless in production mode
    Rails.env.production? && Akismetor.submit_spam(akismet_attributes)
    self.support_identity_id = User.current_user.support_identity_id
  end

  def ham
    raise "Couldn't mark as ham, not logged in." unless User.current_user
    raise "Couldn't mark as ham, not a support volunteer." unless User.current_user.support_volunteer?
    # don't submit ham reports unless in production mode
    Rails.env.production? && Akismetor.submit_ham(akismet_attributes)
    self.support_identity_id = nil
  end

  def take
    raise "Couldn't take, not logged in." unless User.current_user
    raise "Couldn't take, not a support volunteer." unless User.current_user.support_volunteer?
    self.support_identity_id = User.current_user.support_identity_id
    self.watch! unless self.watched?
  end

  def not_mine?
    raise "Couldn't check ownership. Not logged in." unless User.current_user
    self.support_identity_id != User.current_user.support_identity_id
  end

  def steal
    raise "Couldn't steal, not logged in." unless User.current_user
    raise "Couldn't steal, not a support volunteer." unless User.current_user.support_volunteer?
    self.send_steal_notification(User.current_user)
    self.support_identity_id = User.current_user.support_identity_id
  end

  def give!(support_id)
    raise "Couldn't give, not logged in." unless User.current_user
    raise "Couldn't give, not a support volunteer." unless User.current_user.support_volunteer?
    SupportTicketMailer.request_to_take(self, SupportIdentity.find(support_id).user, User.current_user).deliver
  end

  def reopen(reason, email=nil)
    raise "Couldn't reopen. No reason given." if reason.blank?
    if !email.blank? || !User.current_user
      raise "Couldn't reopen. not owner!" unless (self.email == email)
    elsif !User.current_user.support_volunteer?
      raise "Couldn't reopen. not owner!" unless (User.current_user.id == self.user_id)
    end
    self.code_ticket_id = self.faq_id = self.support_identity_id = nil
    self.faq_vote.destroy if self.faq_vote
    self.code_vote.destroy if self.code_vote
    self.support_details.update_all("resolved_ticket = NULL")
  end

  def post
    raise "Couldn't post, not logged in." unless User.current_user
    raise "Couldn't post, not a support volunteer." unless User.current_user.support_volunteer?
    self.support_identity = User.current_user.support_identity
  end

  def needs_fix(code_ticket_id=nil)
    raise "Couldn't set to waiting, not logged in." unless User.current_user
    raise "Couldn't set to waiting, not a support volunteer." unless User.current_user.support_volunteer?
    if code_ticket_id
      code_ticket = CodeTicket.find code_ticket_id # will raise error if no ticket
      raise "can't assign to a duplicate" if code_ticket.code_ticket_id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 2)
    else
      code_ticket = CodeTicket.create(:summary => self.summary, :url => self.url, :browser => self.user_agent)
      code_ticket_id = code_ticket.id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 3)
    end
    self.code_ticket_id = code_ticket_id
    self.support_identity = User.current_user.support_identity
    code_ticket
  end

  def answer(faq_id=nil)
    raise "Couldn't set to answered, not logged in." unless User.current_user
    raise "Couldn't set to answered, not a support volunteer." unless User.current_user.support_volunteer?
    if faq_id
      faq = Faq.find_by_id(faq_id)
      raise "Couldn't set to waiting: no faq with id: #{faq_id}" unless faq
    else
      faq = Faq.create
      faq_id = faq.id
    end
    self.faq_id = faq_id
    self.support_identity = User.current_user.support_identity
    FaqVote.create(:faq_id => faq_id, :support_ticket_id => self.id, :vote => 1)
    faq
  end

  def resolve(resolution)
    raise "Couldn't resolve. No resolution given." if resolution.blank?
    if !User.current_user.try(:support_admin?)
      raise "Couldn't resolve. Not a support admin."
    end
    self.support_identity = User.current_user.support_identity
  end

  # SUPPORT DETAILS stuff
  # only logged in users or the ticket owner can comment
  # only support volunteers can comment on non-open tickets
  def comment!(content, official=true, email=nil)
    if !User.current_user && email
      raise "Couldn't comment. not owner!" unless (self.email == email)
    elsif User.current_user.nil?
      raise "Couldn't comment. Not logged in."
    end
    support_response = (official && User.current_user.support_volunteer?)
    if self.unowned? || support_response || (User.current_user == self.user)
      self.support_details.create(:content => content,
                               :support_identity_id => User.current_user.try(:support_identity).try(:id),
                               :support_response => support_response,
                               :system_log => false)
      self.send_update_notifications
    else
      raise "Couldn't comment. Only official comments allowed."
    end
  end

  def accept(detail_id, email = nil)
    detail = self.support_details.find_by_id(detail_id)
    raise "Couldn't accept answer. No detail with id: #{detail_id}" unless detail
    if !email.blank?
      raise "Couldn't accept answer. not owner!" unless (self.email == email)
    else
      raise "Couldn't accept answer. Not logged in." unless User.current_user
      raise "Couldn't accept answer. not owner!" unless (self.user == User.current_user)
    end
    detail.update_attribute(:resolved_ticket, true)
    self.support_identity_id = nil
  end

  # NOTIFICATION stuff
  attr_accessor :turn_off_notifications

  after_create :add_owner_as_watcher
  def add_owner_as_watcher
    # unless they've asked you not too
    return true if turn_off_notifications == "1"
    # otherwise, add the email supplied in the ticket, or the email of the user who opened it
    self.support_notifications.create(:email => self.email || self.user.email)
  end

  def make_private!(email = nil)
    if !email.blank?
      raise "Couldn't make private. not owner!" unless (self.email == email)
    else
      raise "Couldn't make private. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise "Couldn't make private. Not owner."
      end
    end
    self.update_attribute(:private, true)
    # remove all watchers who aren't support volunteers or owners
    self.support_notifications.where(:public_watcher => true).delete_all
    support_identity_id = User.current_user.try(:support_identity_id)
    official = User.current_user && User.current_user.support_volunteer?
    content = "made private"
    self.support_details.create(:content => content,
                                :support_identity_id => support_identity_id,
                                :support_response => official,
                                :system_log => true)
  end

  def show_username?
    !self.anonymous? && !self.email
  end

  def hide_username!
    if self.email
      raise "Couldn't hide username. Guest tickets don't have usernames"
    else
      raise "Couldn't hide username. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise "Couldn't hide username. Not owner."
      end
    end
    self.update_attribute(:anonymous, true)
    support_identity_id = User.current_user.try(:support_identity_id)
    official = User.current_user && User.current_user.support_volunteer?
    content = "hide username"
    self.support_details.create(:content => content,
                                :support_identity_id => support_identity_id,
                                :support_response => official,
                                :system_log => true)

  end

  def show_username!
    if self.email
      raise "Couldn't show username. Guest tickets don't have usernames"
    else
      raise "Couldn't show username. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise "Couldn't show username. Not owner."
      end
    end
    self.update_attribute(:anonymous, false)
    support_identity_id = User.current_user.support_identity_id
    official = User.current_user && User.current_user.support_volunteer?
    content = "show username"
    self.support_details.create(:content => content,
                                :support_identity_id => support_identity_id,
                                :support_response => official,
                                :system_log => true)

  end

  def mail_to
    self.support_notifications.map(&:email).uniq
  end

  # used in view to determine whether to offer to turn on or off notifications
  def watched?(email = nil)
    email_address = email || User.current_user.try(:email)
    raise "Couldn't check watch. No email address to check." unless email_address
    # if there's no watcher with that email, this will be nil which acts as false
    self.support_notifications.where(:email => email_address).first
  end

  def watch!(email = nil)
    if !email.blank?
      raise "Couldn't watch. not owner!" unless (self.email == email)
      self.support_notifications.create(:email => email)
    else
      raise "Couldn't watch. Not logged in." unless User.current_user
      raise "Couldn't watch. Already watching." if watched?
      public = !User.current_user.support_volunteer?
      raise "Couldn't watch. ticket private!" if (self.private? && public)
      # create a support identity for tracking purposes
      User.current_user.support_identity unless User.current_user.support_identity_id
      self.support_notifications.create(:email => User.current_user.email, :public_watcher => public)
    end
  end

  def unwatch!(email = nil)
    if !email.blank?
      raise "Couldn't remove watch. Not watching." unless watched?(email)
      self.support_notifications.where(:email => email).delete_all
    else
      raise "Couldn't remove watch. Not logged in" unless User.current_user
      raise "Couldn't remove watch. Not watching." unless watched?(User.current_user.email)
      self.support_notifications.where(:email => User.current_user.email).delete_all
    end
  end

  def send_create_notifications
    self.mail_to.each do |recipient|
      SupportTicketMailer.create_notification(self, recipient).deliver
    end
  end

  def send_update_notifications
    self.mail_to.each do |recipient|
      SupportTicketMailer.update_notification(self, recipient).deliver
    end
  end

  def send_steal_notification(current_user)
    SupportTicketMailer.steal_notification(self, current_user).deliver
  end

  # AUTHENTICATION stuff

  before_create :create_authentication_code
  def create_authentication_code
    self.authentication_code = SecureRandom.hex(10) if self.email
  end

  def owner?(code=nil)
    if User.current_user.nil? # not logged in
      return false if self.authentication_code.blank? # not a guest ticket
      code == self.authentication_code # does ticket authentication match authentication code?
    else # logged in
      User.current_user.id == self.user_id  # does ticket owner match current user?
    end
  end

  # SPAM stuff

  before_create :check_for_spam
  def check_for_spam
    errors.add(:base, "^This ticket looks like spam to our system, sorry! Please try again, or create an account to submit.") unless check_for_spam?
  end

  def check_for_spam?
    # don't check for spam unless in production and no user_id
    approved = !Rails.env.production? || self.user_id || !Akismetor.spam?(akismet_attributes)
    self.spam! unless approved
    return approved
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
