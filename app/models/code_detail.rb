class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :pseud

  def byline
    prefix = self.support_response? ? "Support volunteer " : ""
    prefix + self.pseud.name
  end

  before_create :check_for_support
  def check_for_support
    self.support_response = true if self.pseud.try(:support_volunteer)
    return true
  end

end
