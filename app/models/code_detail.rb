class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  def byline
    raise "no support identity" unless self.support_identity
    name = self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
    system = self.system_log? ? "" : " wrote"
    "[#{self.updated_at.to_s(:short)}] #{name}#{system}"
  end
end
