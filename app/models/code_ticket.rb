class CodeTicket < ActiveRecord::Base

  belongs_to :support_identity # the support identity of the last user to work on the ticket
  belongs_to :code_ticket # for dupes
  belongs_to :release_note # when deployed

  has_many :code_votes # for prioritizing (lots of votes = high priority)
  has_many :code_notifications  # a bunch of email addresses for update notifications
  has_many :code_details  # like comments, except non-threaded and with extra attributes
  has_many :support_tickets  # tickets waiting for this fix
  has_many :code_commits # created from git hub pushes

  ### VALIDATIONS and CALLBACKS

  # only support volunteers can open code tickets
  before_validation(:on => :create) do
    raise SecurityError, "only volunteers can create code tickets" if !User.current_user.try(:support_volunteer?)
  end

  # must have summary
  validates_presence_of :summary
  validates_length_of :summary, :maximum=> 140 # tweet length!

  attr_accessor :turn_off_notifications
  # add a default set of watchers to new tickets
  # TODO at the moment, this is just the owner
  after_create :add_default_watchers
  def add_default_watchers
    # on create, add owner to the notifications unless indicated otherwise
    self.watch! unless turn_off_notifications == "1"

    # TODO make default groups. e.g. coders, that people can add and remove themselves to
    # so that when tickets are created the notifications are populated with these groups.
    # when someone is added to that group, add them to all tickets
    # this allows people to remove themselves from individual tickets if they usually watch all
    # and add themselves to individual tickets if they usually don't watch all
    self.send_create_notifications
  end

  ### HELPER METHODS

  # used in lists
  def name
    "Code Ticket #" + self.id.to_s
  end

  def status_line
    if self.unowned?
      "open"
    elsif self.code_ticket_id
      "closed as duplicate by #{self.support_identity.byline}"
    elsif self.release_note_id
      "deployed in #{self.release_note.release} (verified by #{self.support_identity.byline})"
    elsif self.staged?
      "waiting for verification (commited by #{self.support_identity.byline})"
    else
      "#{self.status} by #{self.support_identity.byline}"
    end
  end

  # test if ticket is one I can steal (used in volunteer views)
  def stealable?
    raise SecurityError, "Couldn't check stealable. Not volunteer." unless User.current_user.try(:support_volunteer?)
    self.support_identity_id != User.current_user.support_identity_id &&
      self.current_state.events.include?(:steal)
  end

  # only logged in users can watch code tickets
  def watched?
    raise SecurityError, "Couldn't check watch status. Not logged in." unless User.current_user
    self.code_notifications.where(:email => User.current_user.email).first
  end

  # returns an array of email addresses. [] if none
  def mail_to(private = false)
    notifications = self.code_notifications
    notifications = notifications.official if private
    notifications.map(&:email).uniq
  end

  # change the support id, and add current volunteer to watch list
  def take_and_watch!
    raise SecurityError, "not support volunteer" unless User.current_user.try(:support_volunteer?)
    self.support_identity_id = User.current_user.support_identity_id
    self.watch!
  end

  # only logged in users can vote for code tickets and only once
  def voted?
    raise SecurityError, "Couldn't check vote. Not logged in." unless User.current_user
    self.code_votes.where(:user_id => User.current_user.id).first
  end

  def vote_count
    code_votes.sum(:vote)
  end

  # used in controller to decide which details to show
  def visible_code_details
    User.current_user.try(:support_volunteer?) ? self.code_details : self.code_details.visible_to_all
  end

  # okay until we need to paginate
  # sort by votes
  def <=>(other)
    other.vote_count <=> self.vote_count
  end

  ### FILTER
  def self.filter(params = {})
    tickets = CodeTicket.scoped

    # tickets I am watching, private
    if !params[:watching].blank?
      user = User.current_user
      raise SecurityError unless user
      tickets = tickets.joins(:code_notifications) & CodeNotification.where(:email => user.email)
    end

    # ticket's commented on by user
    if !params[:comments_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:comments_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      # don't include system logs
      details = CodeDetail.written_comments.where(:support_identity_id => support_identity.id)

      # don't include private comments unless support volunteer
      details = details.visible_to_all unless User.current_user.try(:support_volunteer?)

      tickets = tickets.joins(:code_details) & details
    end

    # tickets owned by volunteer
    if !params[:owned_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:owned_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      tickets = tickets.where(:support_identity_id => support_identity.id)
    end

    if !params[:closed_in_release].blank?
      # ignore status because the status must be closed
      release = ReleaseNote.find(params[:closed_in_release]) # raise if non-existent
      tickets = tickets.where(:release_note_id => release.id)
    elsif !params[:status].blank?
      case params[:status]
      when "unowned"
        tickets = tickets.unowned
      when "taken"
        tickets = tickets.taken
      when "committed"
        tickets = tickets.committed
      when "staged"
        tickets = tickets.staged
      when "verified"
        tickets = tickets.verified
      when "closed"
        tickets = tickets.closed
      when "all"
        # no op
      when "open"
        tickets = tickets.where('status != "closed"')
      else
        raise TypeError
      end
    else # default status is not closed (open)
      tickets = tickets.where('status != "closed"')
    end

    # has to come last because sort_by_vote returns an array
    if params[:sort_by]
      case params[:sort_by]
      when "recently updated"
        tickets = tickets.order("updated_at desc")
      when "least recently updated"
        tickets = tickets.order("updated_at asc")
      when "oldest first"
        tickets = tickets.order("id asc")
      when "highest vote"
        tickets = tickets.sort
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
      event :duplicate, :transitions_to => :closed
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
                               :system_log => true)
    end
    after_transition do |from, to, triggering_event, *event_args|
      self.send_update_notifications unless [:steal].include?(triggering_event)
    end
  end

  ### SCOPES and ARRAYS

  # scopes based on workflow states
  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  def self.not_closed
    where('status != "closed"')
  end

  # tickets which can be used for code commit matching
  # once a code ticket has been staged it's being tested, and you can't add more commits to it
  def self.for_matching
    not_closed.where('status != "verified"').where('status != "staged"').order("id desc")
  end

  # returns an array of support ticket ids
  def self.ids
    select("code_tickets.id").map(&:id)
  end

  ### WORKFLOW methods (call with ! to change state)
  # volunteer status is checked by workflow on_transition
  # logs system_log details via workflow on_transition
  # sends notifications via workflow on_transition
  # some methods add you as watcher, some don't. some change owner, some don't

  def take
    self.take_and_watch!
  end

  def duplicate(original_id)
    original = CodeTicket.find original_id # will raise error if no such ticket
    self.code_ticket_id = original_id
    # move all related support tickets
    self.support_tickets.update_all(:code_ticket_id => original_id)
    # move all code notifications unless they are dupes
    self.code_notifications.each {|watcher| watcher.move_to_ticket(original)}
     # move all code votes unless they are dupes
    self.code_votes.each {|vote| vote.move_to_ticket(original) }
    self.support_identity_id = User.current_user.support_identity_id
  end

  def commit(code_commit_id)
    cc = CodeCommit.find(code_commit_id) # will raise unless exists
    raise "code commit already used" if cc.code_ticket_id
    self.support_identity_id = cc.support_identity_id
    cc.code_ticket_id = self.id
    cc.status = "matched"
    cc.save!
    code_committer = cc.support_identity.user
    if code_committer && (code_committer != User.current_user) # matching someone else's code commit
      current = User.current_user
      User.current_user = cc.support_identity.user
      take_and_watch!
      User.current_user = current
    else
      take_and_watch!
    end
  end

  def reject(reason)
    raise "Couldn't reject. No reason given." if reason.blank?
    raise SecurityError, "Couldn't reject. Not support admin." unless User.current_user.support_admin?
    self.take_and_watch!
  end

  def steal
    raise "couldn't steal, not stealable" unless stealable?
    self.send_steal_notification(User.current_user)
    self.take_and_watch!
  end

  def reopen(reason)
    raise "Couldn't reopen. No reason given." if reason.blank?
    self.code_ticket_id = nil
    self.release_note_id = nil
    self.support_identity_id = nil
  end

  # don't update support identity, still belongs to committer
  def stage
    raise SecurityError, "Couldn't stage. Not logged in as support admin." unless User.current_user.support_admin?
    self.code_commits.each {|cc| cc.stage!}
  end

  def verify
    raise "Couldn't verify, same person committed" if User.current_user.support_identity == self.support_identity
    self.code_commits.each {|cc| cc.verify!}
    self.take_and_watch!
  end

  # don't update support identity, still belongs to verifier
  def deploy(release_note_id)
    raise SecurityError, "Couldn't stage. Not logged in as support admin." unless User.current_user.support_admin?
    note = ReleaseNote.find(release_note_id) # will raise error if no release note
    self.release_note_id = release_note_id
    self.code_commits.each {|cc| cc.deploy!}
    self.support_tickets.each {|st| st.deploy!}
  end

  ### META-WORKFLOW
  # admins can change state for multiple tickets at the same time

  # deploy to stage. all commits must be matched
  def self.stage!
    raise SecurityError, "Couldn't stage. Not logged in as support admin." unless User.current_user.support_admin?
    raise "Couldn't stage. Not all commits matched" if CodeCommit.unmatched.count > 0
    CodeCommit.matched.each { |cc| cc.code_ticket.stage! }
  end

  # deploy to production. all tickets must be verified
  # a release note must exist and will be posted
  def self.deploy!(release_note_id)
    raise SecurityError, "Couldn't stage. Not logged in as support admin." unless User.current_user.support_admin?
    raise "Couldn't deploy. Not all tickets verified" if CodeCommit.staged.count > 0
    note = ReleaseNote.find_by_id(release_note_id)
    raise "Couldn't deploy. Release not doesn't exist." unless note
    CodeCommit.verified.each {|cc| cc.code_ticket.deploy!(note.id)}
    note.post!
    return note
  end

  ### NON-WORKFLOW but similar methods.
  # call mailers directly to get notifications.
  # call log! directly to add transitions to details
  # check volunteer status directly when necessary

  # user votes
  def vote!(count = 1)
    raise SecurityError, "Couldn't vote. Not logged in." unless User.current_user
    raise "can't vote for a duplicate" if self.code_ticket_id
    raise "already voted" if voted?
    self.code_votes.create(:user => User.current_user, :vote => count)
  end

  # editing a code ticket. volunteers only
  def update_from_edit!(summary, url, browser)
    raise SecurityError, "Couldn't vote. Not support volunteer." unless User.current_user.try(:support_volunteer?)
    self.summary = summary
    self.url = url
    self.browser = browser
    self.save!
    self.code_details.create(:content => "ticket edited",
                             :support_identity_id => User.current_user.support_identity_id,
                             :support_response => true,
                             :system_log => true)
    self.send_update_notifications
  end

  # only logged in users can comment
  # only support volunteers can comment on non-open tickets
  def comment!(content, response=nil)
    return if content.blank?
    raise SecurityError, "Couldn't comment. Not logged in." unless User.current_user
    support_response = false
    private_response = false
    if response.nil?
      response = User.current_user.support_volunteer? ? "official" : "unofficial"
    end
    case response
    when "official"
      raise SecurityError, "only volunteers can comment officially" unless User.current_user.support_volunteer?
      support_response = true
    when "private"
      raise SecurityError, "only volunteers can comment privately" unless User.current_user.support_volunteer?
      private_response = true
      support_response = true
    when "unofficial"
      raise "Couldn't comment. Only official comments allowed." unless self.unowned?
    end
    self.code_details.create(:content => content,
                             :support_identity_id => User.current_user.support_identity.id,
                             :support_response => support_response,
                             :system_log => false,
                             :private => private_response)
    self.send_update_notifications(private_response)
    # DECISION should notifications be sent before or after you're added to the ticket?
    self.watch! unless self.code_ticket_id
  end

  # only logged in users can watch
  def watch!
    raise "can't watch a duplicate" if self.code_ticket_id
    return true if watched?
    self.code_notifications.create(:email => User.current_user.email, :official => User.current_user.support_volunteer?)
  end

  def unwatch!
    raise "Couldn't remove watch. Not watching." unless watched?
    self.code_notifications.where(:email => User.current_user.email).destroy_all
  end

  ### SEND NOTIFICATIONS

  def send_create_notifications
    self.mail_to.each do |recipient|
      CodeTicketMailer.create_notification(self, recipient).deliver
    end
  end

  def send_update_notifications(private = false)
    self.mail_to(private).each do |recipient|
      CodeTicketMailer.update_notification(self, recipient).deliver
    end
  end

  def send_steal_notification(stealer)
    CodeTicketMailer.steal_notification(self, stealer).deliver
  end

  # SANITIZER stuff

  attr_protected :summary_sanitizer_version
  def sanitized_summary
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :summary
    summary.html_safe
  end

end
