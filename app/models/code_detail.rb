class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  def byline
    prefix = self.support_response? ? "Support volunteer " : ""
    prefix + self.support_identity.name
  end
end
