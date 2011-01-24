class CodeCommit < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  validates_presence_of :author

  def name
    "Code Commit ##{self.id}"
  end

  def summary
    return "" if self.message.blank?
    first_line = self.message.split("\n").first
    return first_line if first_line.size < 140
    snip_idx = first_line.index(/\s/, 100)
    return first_line unless snip_idx
    first_line[0, snip_idx] + "..."
  end

  def self.create_commits_from_json(payload)
    pushed_at = payload["repository"]["pushed_at"].to_time
    commits = payload["commits"]
    commits.each do |commit|
      CodeCommit.create!(:author => commit["author"]["name"],
                         :message => commit["message"],
                         :url => commit["url"],
                         :pushed_at => pushed_at)
    end
  end

  # concise representation of all info except message, url and associated code ticket
  def info
    date = self.pushed_at.to_s(:short)
    "[#{date}] #{self.support_identity.byline} (#{self.status})"
  end

  before_create :ensure_support_identity
  def ensure_support_identity
    identity = SupportIdentity.find_by_name(self.author)
    # NOTE just the support identity is created. to make a user a support volunteer, the
    # support identity needs to be associated with the user
    # also, if someone is already using that name as their support identities, they'll get credited for
    # the submit, but it won't be filterable, because they're not official
    # TODO create an admin interface for managing support volunteers
    # create new support identities or match them with unmatched existing ones (created from github commits)
    identity = SupportIdentity.create(:name => self.author, :official => true) unless identity
    self.support_identity = identity
  end

  after_create :match_to_code_ticket
  def match_to_code_ticket
    return unless self.message
    match = self.message.match /issue (\d+)/
    if match
      ticket = CodeTicket.find_by_id(match[1])
      return unless ticket
      user = self.support_identity.user || ticket.support_identity.try(:user)
      if user
        User.current_user = user
        self.match!(ticket.id)
      end
    end
  end

  # filter code commits
  def self.filter(params = {})
    commits = CodeCommit.scoped

    # commits owned by volunteer
    if !params[:owned_by_support_identity].blank?
      support_identity = SupportIdentity.find_by_name(params[:owned_by_support_identity])
      raise ActiveRecord::RecordNotFound unless support_identity
      commits = commits.where(:support_identity_id => support_identity.id)
    end

    # filter by status
    if !params[:status].blank?
      case params[:status]
      when "unmatched"
        commits = commits.unmatched
      when "matched"
        commits = commits.matched
      when "staged"
        commits = commits.staged
      when "verified"
        commits = commits.verified
      when "deployed"
        commits = commits.deployed
      when "all"
        # no op
      else
        raise TypeError
      end
    else # default status is unmatched
      commits = commits.unmatched
    end

    if params[:sort_by]
      case params[:sort_by]
      when "oldest first"
        commits = commits.order("id asc")
      when "newest first"
        commits = commits.order("id desc")
      else
        raise TypeError
      end
    else # "newest first" by default
      commits = commits.order("id desc")
    end

    return commits
  end

  # STATUS/RESOLUTION stuff
  include Workflow
  workflow_column :status

  workflow do
    state :unmatched do
      event :match, :transitions_to => :matched
    end
    state :matched do
      event :unmatch, :transitions_to => :unmatched
      event :stage, :transitions_to => :staged
    end
    state :staged do
      event :unmatch, :transitions_to => :unmatched
      event :verify, :transitions_to => :verified
    end
    state :verified do
      event :deploy, :transitions_to => :deployed
    end
    state :deployed
  end

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

  def self.ids
    select("code_commits.id").map(&:id)
  end

  def match(code_ticket_id)
    ticket = CodeTicket.find code_ticket_id
    # if this code ticket can commit the ticket, commit the ticket
    if ticket.current_state.events[:commit]
      ticket.commit!(self.id)
    else # otherwise, just create the link
      self.code_ticket_id = ticket.id
    end
  end

  def unmatch
    raise SecurityError, "not logged in!" unless User.current_user
    raise SecurityError, "not a support volunteer!" unless User.current_user.support_volunteer?
    ticket = CodeTicket.find self.code_ticket_id
    # if the ticket was committed on the basis of this one commit, reopen it
    if ticket.code_commits == [self] && ticket.committed?
      ticket.reopen!("unmatched from code commit")
    end
    self.code_ticket_id = nil
  end


end
