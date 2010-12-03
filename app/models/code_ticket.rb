class CodeTicket < ActiveRecord::Base

  belongs_to :pseud
  belongs_to :admin_post
  belongs_to :known_issue
  has_many :code_details
  has_many :code_watchers
  has_many :code_votes

  # SCOPES

  def self.owned_by(pseud_id)
    where(:pseud_id => pseud_id)
  end

  # VOTES

  def votes
    code_votes.sum(:vote)
  end

  # NOTIFICATION STUFF

  def mail_to
    code_watchers.map(&:email).join(", ")
  end

  # SANITIZER stuff

  attr_protected :summary_sanitizer_version
  def sanitized_summary
    sanitize_field self, :summary
  end

end
