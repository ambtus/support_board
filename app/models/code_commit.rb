class CodeCommit < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  validates_presence_of :author

  before_create :find_support_identity
  def find_support_identity
    self.support_identity = SupportIdentity.find_by_name(self.author)
  end

  after_create :match_to_code_ticket
  def match_to_code_ticket
    return unless self.message
    match = self.message.match /issue (\d+)/
    if match
      ticket = CodeTicket.find_by_id(match[1])
      ticket.commit!(self.id) if ticket
    end
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
      event :deploy, :transitions_to => :deployed
    end
    state :verified
  end

  self.workflow_spec.state_names.each do |state|
    scope state, :conditions => { :status => state.to_s }
  end

end
