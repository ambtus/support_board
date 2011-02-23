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

  # make a ticket consistently either a guest ticket or a user ticket
  before_validation(:on => :create) do
    if User.current_user
      self.user = User.current_user
      self.email = nil # just to be on the safe side
    else
      self.anonymous = false # guests are already anonymous
      self.authentication_code = SecureRandom.hex(10)
    end
    true # ensure we reach validations for better error messages
  end

  # must have valid email if guest ticket
  validates :email, :email_veracity => {:on => :create, :unless => :user_id}

  # must have authentication code if guest ticket
  validates_presence_of :authentication_code, :on => :create, :unless => :user_id

  # must have a (short) summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  attr_accessor :turn_off_notifications
  attr_accessor :no_comments

  # add a default set of watchers to new tickets
  # TODO at the moment, this is just the owner
  after_create :add_default_watchers
  def add_default_watchers
    # on create, add owner to the notifications unless indicated otherwise
    self.watch!(self.authentication_code) unless turn_off_notifications == "1"

    # TODO make default groups. e.g. testers, that people can add and remove themselves to
    # so that when tickets are created the notifications are populated with these groups.
    # when someone is added to that group, add them to all tickets (respecting privacy)
    # this allows people to remove themselves from individual tickets if they usually watch all
    # and add themselves to individual tickets if they usually don't watch all
    self.send_create_notifications if self.no_comments
  end

  # FIXME make this a background job so it's asyncronous and can be retried
  before_create :get_browser_hash_string_from_agent
  def get_browser_hash_string_from_agent
    return if user_agent.blank?
    Rails.logger.debug "querying useragent"
    url = URI.parse('http://www.useragentstring.com/')
    request = Net::HTTP::Post.new(url.path)
    request.set_form_data({'uas' => self.user_agent, 'getJSON' => "all"})
    response = begin
      Net::HTTP.new(url.host, url.port).start do |http|
        http.read_timeout = 5
        http.request(request)
      end
    rescue Timeout::Error
      "timeout error"
    rescue SocketError
      "network down?"
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

  # human language interpretation of status
  # TODO needs translation
  def status_line
    if self.unowned?
      "open"
    elsif self.waiting?
      "waiting for a code fix" # should be followed by link to code ticket
    elsif self.waiting_on_admin?
      "waiting for an admin"
    elsif self.spam?
      "spam"
    elsif self.closed? && self.support_identity_id.nil?
      "closed by owner"
    elsif self.closed? && self.code_ticket_id
      "fixed in release"  # should be followed by link to release note
    elsif self.closed? && self.faq_id
      "answered by FAQ"  # should be followed link to faq
    else
      "#{self.status} by #{self.support_identity.name}"
    end
  end

  def release_note
    return nil unless self.closed?
    return nil unless self.code_ticket_id
    release_note = self.code_ticket.release_note
  end

  # ticket was opened by a guest with an email address
  def guest_ticket?
    self.email
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

  # used in watch! so don't get duplicate notifications
  # also used in non-guest views to determine whether to offer to turn on or off notifications
  # returns the support notification if it exists, nil otherwise
  def watched?(code = nil)
    code.blank? ? raise_unless_logged_in : raise_unless_guest_owner(code)
    email_to_check = User.current_user ? User.current_user.email : self.email
    self.support_notifications.where(:email => email_to_check).first
  end

  # the current user is neither a volunteer, nor the owner of the ticket
  def public_watcher?
    User.current_user && !User.current_user.support_volunteer? && (self.user != User.current_user)
  end

  # test if ticket is one I can steal (used in volunteer views)
  def stealable?
    raise_unless_volunteer
    self.support_identity_id != User.current_user.support_identity_id &&
      self.current_state.events.include?(:steal)
  end

  # change the support id, and add current volunteer to watch list
  def take_and_watch!
    raise_unless_volunteer
    self.support_identity_id = User.current_user.support_identity_id
    self.watch!
  end

  # list of email addresses for notifications
  def mail_to(private = false)
    notifications = self.support_notifications
    notifications = notifications.official if private
    notifications.map(&:email).uniq
  end

  def visible_support_details
    User.current_user.try(:support_volunteer?) ? self.support_details : self.support_details.visible_to_all
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
      raise SecurityError, "can't determine what email to check" unless User.current_user
      tickets = tickets.joins(:support_notifications) & SupportNotification.where(:email => User.current_user.email)
    end

    # if we haven't already checked, rule out private tickets
    if params[:owned_by_user].blank? && params[:watching].blank?
      tickets = tickets.where(:private => false) unless User.current_user.try(:support_volunteer?)
    end

    # ticket's commented on by a user
    if !params[:comments_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:comments_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity

      # don't include system logs
      details = SupportDetail.written_comments.where(:support_identity_id => support_identity.id)

      # don't include private comments unless support volunteer
      details = details.visible_to_all unless User.current_user.try(:support_volunteer?)

      tickets = tickets.joins(:support_details) & details
    end

    # tickets owned by a specific volunteer
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

    # TODO add sorting to view
    if params[:sort_by]
      case params[:sort_by]
      when "recently updated"
        tickets = tickets.order("updated_at desc")
      when "least recently updated"
        tickets = tickets.order("updated_at asc")
      when "oldest first"
        tickets = tickets.order("id asc")
      when "newest"
        tickets = tickets.order("id desc")
      else
        raise TypeError
      end
    else # "newest" by default
      tickets = tickets.order("id desc")
    end

    return tickets

  end

  # WORKFLOW / STATE MACHINE
  include Workflow
  workflow_column :status

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
    state :posted do
      event :reopen, :transitions_to => :unowned
    end
    state :spam do
      event :ham, :transitions_to => :unowned
    end
    state :taken do
      event :steal, :transitions_to => :taken
      event :reopen, :transitions_to => :unowned
      event :needs_fix, :transitions_to => :waiting
      event :answer, :transitions_to => :closed
      event :accept, :transitions_to => :closed
      event :needs_admin, :transitions_to => :waiting_on_admin
      event :resolve, :transitions_to => :closed
    end
    state :waiting_on_admin do
      event :reopen, :transitions_to => :unowned
      event :resolve, :transitions_to => :closed
    end
    state :waiting do
      event :reopen, :transitions_to => :unowned
      event :deploy, :transitions_to => :closed
    end
    state :closed do
      event :reopen, :transitions_to => :unowned
    end

    on_transition do |from, to, triggering_event, *event_args|
      next if self.new_record?
      content = "#{from} -> #{to}"
      content += " (#{event_args.first})" unless event_args.blank?
      log!(content)
    end
    after_transition do |from, to, triggering_event, *event_args|
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

  ### WORKFLOW methods (call with ! to change state)
  # logs system_log details via workflow on_transition
  # sends notifications via workflow on_transition
  # some methods add you as watcher, some don't. some raise_unless_volunteer, some don't.

  def spam
    raise_unless_volunteer
    raise ArgumentError, "user tickets can't be spam" unless guest_ticket?
    # don't submit spam reports unless in production mode
    Rails.env.production? && Akismetor.submit_spam(akismet_attributes)
    self.take_and_watch!
  end

  def ham
    raise_unless_volunteer
    # don't submit ham reports unless in production mode
    Rails.env.production? && Akismetor.submit_ham(akismet_attributes)

    # marking as ham is similar to re-opening
    self.support_identity_id = nil
  end

  def take
    raise_unless_volunteer
    self.take_and_watch!
  end

  def steal
    raise "couldn't steal, not stealable" unless stealable?
    self.send_steal_notification
    self.take_and_watch!
  end

  def reopen(reason, code=nil)
    raise ArgumentError, "Couldn't reopen. No reason given." if reason.blank?
    raise_unless_owner_or_volunteer(code)

    self.code_ticket_id = self.faq_id = self.support_identity_id = nil
    self.faq_vote.destroy if self.faq_vote
    self.code_vote.destroy if self.code_vote
    self.support_details.update_all("resolved_ticket = NULL")
  end

  def post
    raise_unless_volunteer
    self.take_and_watch!
  end

  def needs_fix(code_ticket_id=nil)
    self.take_and_watch!
    if code_ticket_id
      code_ticket = CodeTicket.find code_ticket_id # will raise error if no ticket
      raise ArgumentError, "can't assign to a duplicate" if code_ticket.code_ticket_id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 2)
    else
      visible_url = self.anonymous? ? nil : self.url
      code_ticket = CodeTicket.create(:summary => self.summary,
         :url => visible_url,
         :browser => self.browser_string)
      code_ticket_id = code_ticket.id
      CodeVote.create(:code_ticket_id => code_ticket_id, :support_ticket_id => self.id, :vote => 3)
    end
    self.code_ticket_id = code_ticket_id
    return code_ticket
  end

  def answer(faq_id)
    faq = Faq.find(faq_id) # will raise if no faq
    self.take_and_watch!
    self.faq_id = faq_id
    FaqVote.create(:faq_id => faq_id, :support_ticket_id => self.id, :vote => 2)
  end

  def resolve(resolution)
    raise ArgumentError, "Couldn't resolve. No resolution given." if resolution.blank?
    raise_unless_admin
    self.take_and_watch!
  end

  def accept(detail_id, code=nil)
    detail = self.support_details.find(detail_id) # will raise if no detail
    code.blank? ? raise_unless_user_owner : raise_unless_guest_owner(code)
    detail.update_attribute(:resolved_ticket, true)
    self.support_identity_id = nil
  end

  ### NON-WORKFLOW but similar methods.
  # call mailers directly to get notifications.
  # call log! directly to add transitions to details

  # add current user or ticket owner to watchers
  def watch!(code = nil)
    return true if watched?(code)
    if User.current_user
      raise_if_public_watcher if self.private?
      self.support_notifications.create!(:email => User.current_user.email,
                                        :public_watcher => public_watcher?,
                                        :official =>  User.current_user.support_volunteer?)
    else
      raise_unless_guest_owner(code)
      self.support_notifications.create!(:email => self.email)
    end
  end

  # remove current user or ticket owner from watchers
  def unwatch!(code = nil)
    notification = self.watched?(code)
    raise "Couldn't remove watch. Not watching." unless notification
    notification.destroy
  end

  # send a notification to another volunteer requesting that they take (or steal) the ticket
  def give!(support_id)
    raise_unless_volunteer # only volunteers can send email to other volunteers
    volunteer_to_take = SupportIdentity.official.find(support_id) # will raise if doesn't exist
    SupportTicketMailer.request_to_take(self, volunteer_to_take.user, User.current_user).deliver
  end

  # comments left by logged in users.
  def user_comment!(content, response=nil)
    return if content.blank?
    raise_unless_logged_in
    support_response = false
    private_response = false
    if response.nil?
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
    when "unofficial"
      raise_unless_user_owner if (self.private? || !self.unowned?)
    end
    comment!(content, support_response, private_response)
  end

  # comments left by logged out users
  def guest_owner_comment!(content, code)
    return if content.blank?
    raise_unless_guest_owner(code)
    comment!(content, false, false)
  end

  private # don't call comment! without authentication and validation from public methods

  # leaves a non-system_log comment on the ticket. sends notifications.
  def comment!(content, official_comment, private_comment)
    comment = self.support_details.create(:content => content,
                               :support_identity_id => User.current_user.try(:support_identity).try(:id),
                               :support_response => official_comment,
                               :system_log => false,
                               :private => private_comment)
    self.send_update_notifications(private_comment)
    return comment
  end

  public

  # make a support ticket visible to owner and official volunteers only. can't be undone.
  # removes watchers who are not the owner or volunteers
  def make_private!(code=nil)
    raise_unless_owner_or_volunteer(code)
    self.update_attribute(:private, true)
    notifications = self.support_notifications.where(:public_watcher => true)
    Rails.logger.debug "removing public watchers: #{notifications.map(&:email)}"
    notifications.delete_all
    log!("made private")
  end

  # makes anonymous.
  def hide_username!
    raise "Couldn't hide username. Guest tickets don't have usernames" if guest_ticket?
    raise_unless_owner_or_volunteer
    self.update_attribute(:anonymous, true)
    support_identity_id = User.current_user.try(:support_identity_id)
    log!("hide username")
  end

  # remove anonymity
  def show_username!
    raise "Couldn't show username. Guest tickets don't have usernames" if guest_ticket?
    raise_unless_user_owner
    self.update_attribute(:anonymous, false)
    support_identity_id = User.current_user.support_identity_id
    log!("show username")
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

  def send_steal_notification
    raise_unless_volunteer
    SupportTicketMailer.steal_notification(self, User.current_user).deliver
  end

  # SPAM stuff

  before_create :check_for_spam
  def check_for_spam
    errors.add(:base, Akismetor::SPAM_MESSAGE) unless is_not_spam?
  end

  def is_not_spam?
    # don't check with Akismetor unless in production and no user_id
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

  private

  def log!(content)
    raise ArgumentError, "content can't be blank" if content.blank?
    # when a support volunteer triggers a system log, it can't be official in order to preserve anonymity
    official = User.current_user && User.current_user.support_volunteer? && (User.current_user != self.user)
    self.support_details.create!(:content => content,
                                 :support_identity_id => User.current_user.try(:support_identity_id),
                                 :support_response => official,
                                 :system_log => true)

  end

  private

  ### a bunch of methods which raise SecurityError

  def raise_unless_logged_in
    raise SecurityError, "not logged in!" unless User.current_user
  end

  def raise_unless_guest_owner(code_to_test)
    raise SecurityError, "can't check guest owner if logged in!" if User.current_user
    actual_code = self.authentication_code
    raise SecurityError, "can't check guest owner if not guest ticket!" unless actual_code
    raise SecurityError, "authentication code mismatch!" if actual_code != code_to_test
  end

  def raise_unless_user_owner
    raise_unless_logged_in
    raise SecurityError, "trying to check user owner on a guest ticket!" unless self.user_id
    raise SecurityError, "not user owner!" unless (self.user_id == User.current_user.id)
  end

  def raise_unless_owner_or_volunteer(code_to_test=nil)
    if code_to_test.blank?
      raise_unless_logged_in
      raise SecurityError, "neither owner nor volunteer!" unless (User.current_user.support_volunteer? || self.user == User.current_user)
    else
      raise_unless_guest_owner(code_to_test)
    end
  end

  def raise_unless_volunteer
    raise_unless_logged_in
    raise SecurityError, "not a support volunteer!" unless User.current_user.support_volunteer?
  end

  def raise_unless_admin
    raise_unless_logged_in
    raise SecurityError, "not a support admin!" unless User.current_user.support_admin?
  end

  # logged in, but neither owner nor official volunteer
  def raise_if_public_watcher
    raise SecurityError, "not authorized!" if public_watcher?
  end


end
