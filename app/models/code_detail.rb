class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :pseud

  def byline
    prefix = self.support_response? ? "Support volunteer " : ""
    prefix + self.pseud.name
  end
end
