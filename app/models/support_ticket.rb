class SupportTicket < ActiveRecord::Base

  belongs_to :user   # the user who opened the ticket (optional)
  belongs_to :support_identity  # the support_identity of the user who is working on the ticket
  belongs_to :faq  # for tickets closed by answering with a FAQ
  has_one :faq_vote # automatic votes when associated with a code ticket
  belongs_to :code_ticket  # for waiting tickets. closed when the code ticket is deployed
  has_one :code_vote # automatic votes when associated with a code ticket
  has_many :support_notifications  # a bunch of email addresses for update notifications
  has_many :support_details  # like comments, except non-threaded and with extra attributes

  ### VALIDATIONS and CALLBACKS

  before_validation(:on => :create) do
    if !self.email.blank?
      self.anonymous = false # guests are already anonymous
      self.authentication_code = SecureRandom.hex(10)
    else
      self.user = User.current_user
    end
    return true
  end

  # must have valid email unless logged in
  validates :email, :email_veracity => {:on => :create, :unless => :user_id}

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  attr_accessor :turn_off_notifications

  # add a default set of watchers to new tickets
  # TODO at the moment, this is just the owner
  after_create :add_default_watchers
  def add_default_watchers
    # Add owner
    # when you create a ticket you should be added to the notifications unless you indicate otherwise
    # add the email supplied in the ticket, or the email of the user who opened it
    email = self.email
    Rails.logger.debug "adding owner as watcher"
    self.watch! unless turn_off_notifications == "1"

    # TODO make default groups. e.g. testers, that people can add and remove themselves to
    # so that when tickets are created the notifications are populated with these groups.
  end

  # TODO make this a delayed job so it's asyncronous and can be retried
  before_create :get_browser_hash_string_from_agent
  def get_browser_hash_string_from_agent
    Rails.logger.debug "querying useragent"
    url = URI.parse('http://www.useragentstring.com/')
    request = Net::HTTP::Post.new(url.path)
    request.set_form_data({'uas' => self.user_agent, 'getJSON' => "all"})
    response = Net::HTTP.new(url.host, url.port).start do |http|
      http.read_timeout = 5
      http.request(request)
    end

    case response
    when Net::HTTPSuccess, Net::HTTPRedirection
      hash =JSON.parse(response.body)
      hash.delete_if {|key, value| value.blank? || value == "unknown" || value == "Null"}
      Rails.logger.debug "found useragent: #{hash}"
    else
      Rails.logger.debug "problem with useragent request: #{response}"
      hash = {}
    end
    self.browser = YAML.dump(hash) unless hash.blank?
    hash
  end

  ### HELPER METHODS

  # recreate hash out of saved string
  def browser_hash
    return {} if self.browser.blank?
    YAML.load(self.browser).symbolize_keys
  end

  # browser information moved to code tickets
  def browser_string
    "#{self.browser_hash[:agent_name]} #{self.browser_hash[:agent_version]} (#{self.browser_hash[:os_name]})"
  end

  # name, for when summary isn't practical
  def name
    "Support Ticket #" + self.id.to_s
  end

  # basic information, usually put after the name or summary
  def parens
    "(" +
    (self.email ? "a guest" : (self.anonymous? ? "a user" : self.user.login)) +
    (self.private? ? " [Private]" : "") +
    ")"
  end

  # used in controller to determine whether to show owner view
  def owner?(code=nil)
    if User.current_user.nil? # not logged in
      return false if self.authentication_code.blank? # not a guest ticket
      code == self.authentication_code # does ticket authentication match authentication code?
    else # logged in
      User.current_user.id == self.user_id  # does ticket owner match current user?
    end
  end

  # test if ticket is one I can steal (used in volunteer views)
  def stealable?
    raise SecurityError, "Couldn't check stealable. Not logged in." unless User.current_user
    self.support_identity_id != User.current_user.support_identity_id &&
      self.current_state.events.include?(:steal)
  end

  # is the ticket's user's name visible? returns false for guest tickets
  def show_username?
    !self.anonymous? && !self.email
  end

  # list of email addresses for notifications
  def mail_to(private = false)
    notifications = self.support_notifications
    notifications = notifications.official if private
    notifications.map(&:email).uniq
  end

  # used in watch! so don't get duplicate notifications
  # also used in view to determine whether to offer to turn on or off notifications
  # TODO? add a preference that always makes this return true (for someone who never wants email)
  # returns the support notification if it exists, nil otherwise
  def watched?
    if User.current_user
      self.support_notifications.where(:email => User.current_user.email).first
    else
      self.support_notifications.where(:email => self.email).first
    end
  end

  ### FILTER
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
      raise SecurityError, "can't filter on watching if not logged in" unless user
      tickets = tickets.joins(:support_notifications) & SupportNotification.where(:email => user.email)
    end

    # if you are filtering by user, the test for private tickets has already been done
    if params[:owned_by_user].blank? && params[:watching].blank?
      tickets = tickets.where(:private => false) unless User.current_user.try(:support_volunteer?)
    end

    # ticket's commented on by user (don't include system logs or private comments)
    if !params[:comments_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:comments_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      tickets = tickets.joins(:support_details) & SupportDetail.public_comments.where(:support_identity_id => support_identity.id)
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
        raise ArgumentError, "no such status"
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

  # WORKFLOW / STATE MACHINE
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
      content = "#{from} -> #{to}"
      content += " (#{event_args.first})" unless event_args.blank?
      self.support_details.create(:content => content,
                               :support_identity_id => User.current_user.try(:support_identity_id),
                               :system_log => true)
      # TODO FIXME: sends notifications with ticket in previous state
      self.send_update_notifications unless [:spam, :ham, :steal].include?(triggering_event)
    end
  end

  ### SCOPES and ARRAYS
  # scopes based on workflow states
  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  # returns an array of support ticket ids
  def self.ids
    select("support_tickets.id").map(&:id)
  end

  ### WORKFLOW methods (call with ! to change state) send notifications via workflow on_transition
  # some workflow methods add you to the watcher list

  def spam
    raise SecurityError, "Couldn't mark as spam, not logged in." unless User.current_user
    raise SecurityError, "Couldn't mark as spam, not a support volunteer." unless User.current_user.support_volunteer?
    # don't submit spam reports unless in production mode
    Rails.env.production? && Akismetor.submit_spam(akismet_attributes)
    self.support_identity_id = User.current_user.support_identity_id
    # marking a ticket spam adds you to the watcher list
    # so someone gets the reply if the owner comments that it was not spam
    # you can always take yourself off if the ticket itself is spammed by the spammer
    self.watch!
  end

  def ham
    raise SecurityError, "Couldn't mark as ham, not logged in." unless User.current_user
    raise SecurityError, "Couldn't mark as ham, not a support volunteer." unless User.current_user.support_volunteer?
    # don't submit ham reports unless in production mode
    Rails.env.production? && Akismetor.submit_ham(akismet_attributes)
    self.support_identity_id = nil
  end

  def take
    raise SecurityError, "Couldn't take, not logged in." unless User.current_user
    raise SecurityError, "Couldn't take, not a support volunteer." unless User.current_user.support_volunteer?
    self.support_identity_id = User.current_user.support_identity_id
    # taking a ticket adds you to the watcher list
    self.watch!
  end

  def steal
    raise SecurityError, "Couldn't steal, not logged in." unless User.current_user
    raise SecurityError, "Couldn't steal, not a support volunteer." unless User.current_user.support_volunteer?
    self.send_steal_notification(User.current_user)
    self.support_identity_id = User.current_user.support_identity_id
    # stealing a ticket adds you to the watcher list
    self.watch!
  end

  def reopen(reason, email=nil)
    raise ArgumentError, "Couldn't reopen. No reason given." if reason.blank?
    if !email.blank? || !User.current_user
      raise SecurityError, "Couldn't reopen. not owner!" unless (self.email == email)
    elsif !User.current_user.support_volunteer?
      raise SecurityError, "Couldn't reopen. not owner!" unless (User.current_user.id == self.user_id)
    end
    self.code_ticket_id = self.faq_id = self.support_identity_id = nil
    self.faq_vote.destroy if self.faq_vote
    self.code_vote.destroy if self.code_vote
    self.support_details.update_all("resolved_ticket = NULL")
  end

  def post
    raise SecurityError, "Couldn't post, not logged in." unless User.current_user
    raise SecurityError, "Couldn't post, not a support volunteer." unless User.current_user.support_volunteer?
    self.support_identity = User.current_user.support_identity
    # posting a ticket adds you to the watcher list
    # so someone gets the reply if the owner comments that they don't want it posted
    self.watch!
  end

  def needs_fix(code_ticket_id=nil)
    raise SecurityError, "Couldn't set to waiting, not logged in." unless User.current_user
    raise SecurityError, "Couldn't set to waiting, not a support volunteer." unless User.current_user.support_volunteer?
    if code_ticket_id
      code_ticket = CodeTicket.find code_ticket_id # will raise error if no ticket
      raise ArgumentError, "can't assign to a duplicate" if code_ticket.code_ticket_id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 2)
    else
      code_ticket = CodeTicket.create(:summary => self.summary, :url => self.url, :browser => self.browser_string)
      code_ticket_id = code_ticket.id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 3)
    end
    self.code_ticket_id = code_ticket_id
    self.support_identity = User.current_user.support_identity
    code_ticket
  end

  def answer(faq_id=nil)
    raise SecurityError, "Couldn't set to answered, not logged in." unless User.current_user
    raise SecurityError, "Couldn't set to answered, not a support volunteer." unless User.current_user.support_volunteer?
    if faq_id
      faq = Faq.find(faq_id) # will raise if no faq
    else
      faq = Faq.create!(:summary => self.summary, :content => "EDIT ME")
      faq_id = faq.id
    end
    self.faq_id = faq_id
    self.support_identity = User.current_user.support_identity
    FaqVote.create(:faq_id => faq_id, :support_ticket_id => self.id, :vote => 1)
    faq
  end

  def resolve(resolution)
    raise ArgumentError, "Couldn't resolve. No resolution given." if resolution.blank?
    if !User.current_user.try(:support_admin?)
      raise SecurityError, "Couldn't resolve. Not a support admin."
    end
    self.support_identity = User.current_user.support_identity
  end

  def accept(detail_id, email = nil)
    detail = self.support_details.find(detail_id) # will raise if no detail
    if !email.blank?
      raise SecurityError, "Couldn't accept answer. not owner!" unless (self.email == email)
    else
      raise SecurityError, "Couldn't accept answer. Not logged in." unless User.current_user
      raise SecurityError, "Couldn't accept answer. not owner!" unless (self.user == User.current_user)
    end
    detail.update_attribute(:resolved_ticket, true)
    self.support_identity_id = nil
  end

  ### NON-WORKFLOW but similar methods.
  # call mailers directly to get notifications.
  # create support details directly to get system_log details

  # send a notification to another volunteer requesting that they take (or steal) the ticket
  def give!(support_id)
    raise SecurityError, "Couldn't give, not logged in." unless User.current_user
    raise SecurityError, "Couldn't give, not a support volunteer." unless User.current_user.support_volunteer?
    new_support_volunteer = SupportIdentity.find(support_id) # will raise if doesn't exist
    raise SecurityError, "can't give to someone who's not a volunteer" unless new_support_volunteer.official?
    SupportTicketMailer.request_to_take(self, new_support_volunteer.user, User.current_user).deliver
  end

  # leaves a non-system_log comment on the ticket. sends notifications.
  def comment!(content, official=true, email=nil, private = false)
    # only logged in users or the ticket owner can comment
    if !User.current_user && email
      raise SecurityError, "Couldn't comment. not owner!" unless (self.email == email)
    elsif User.current_user.nil?
      raise SecurityError, "Couldn't comment. Not logged in."
    end
    support_response = (official && User.current_user.support_volunteer?)
    raise ArgumentError, "Only official comments can be private" if private && !support_response
    # only support volunteers or owners can comment on non-unowned or private tickets
    if (self.unowned? && !self.private?) || support_response || (User.current_user == self.user)
      self.support_details.create(:content => content,
                               :support_identity_id => User.current_user.try(:support_identity).try(:id),
                               :support_response => support_response,
                               :system_log => false,
                               :private => private)
      self.send_update_notifications(private)
    else
      raise SecurityError, "Couldn't comment. Only official comments allowed."
    end
  end

  # makes a ticket private (visible only to volunteers). can't be undone.
  # removes notifications from watchers who are not the owner or volunteers
  def make_private!(email = nil)
    if !email.blank?
      raise SecurityError, "Couldn't make private. not owner!" unless (self.email == email)
    else
      raise SecurityError, "Couldn't make private. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise SecurityError, "Couldn't make private. Not owner."
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

  # makes anonymous.
  def hide_username!
    if self.email
      raise "Couldn't hide username. Guest tickets don't have usernames"
    else
      raise SecurityError, "Couldn't hide username. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise SecurityError, "Couldn't hide username. Not owner."
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

  # remove anonymity
  def show_username!
    if self.email
      raise "Couldn't show username. Guest tickets don't have usernames"
    else
      raise SecurityError, "Couldn't show username. Not logged in." unless User.current_user
      if !User.current_user.support_volunteer? && (User.current_user != self.user)
        raise SecurityError, "Couldn't show username. Not owner."
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

  # add current user or ticket owner to watchers
  def watch!
    if User.current_user
      public_watcher = !User.current_user.support_volunteer?
      raise SecurityError, "Couldn't watch. ticket private!" if (public_watcher && self.private? && !owner?)
      # create a support identity if one doesn't exist
      User.current_user.support_identity unless User.current_user.support_identity_id
      self.support_notifications.create(:email => User.current_user.email, :public_watcher => public_watcher)
    else
      self.support_notifications.create(:email => self.email)
    end
  end

  # add current user or ticket owner from watchers
  def unwatch!
    notification = self.watched?
    raise "Couldn't remove watch. Not watching." unless notification
    notification.destroy
  end

  ### SEND NOTIFICATIONS

  # on create
  def send_create_notifications
    self.mail_to.each do |recipient|
      SupportTicketMailer.create_notification(self, recipient).deliver
    end
  end

  def send_update_notifications(private = false)
    self.mail_to(private).each do |recipient|
      SupportTicketMailer.update_notification(self, recipient).deliver
    end
  end

  def send_steal_notification(current_user)
    SupportTicketMailer.steal_notification(self, current_user).deliver
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
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :summary
    summary.html_safe
  end

end
