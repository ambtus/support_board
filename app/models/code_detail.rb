class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  scope :system_log, where(:system_log => true)
  scope :visible_to_all, where(:private => false)

  def self.public_comments
    where(:private => false).where(:system_log => false)
  end

  def byline
    raise "no support identity" unless self.support_identity
    name = self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
    system = self.system_log? ? "" : " wrote"
    private = self.private? ? " [private]" : ""
    "[#{self.updated_at.to_s(:short)}] #{name}#{system}#{private}"
  end
end
