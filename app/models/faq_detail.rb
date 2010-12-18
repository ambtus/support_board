class FaqDetail < ActiveRecord::Base
  belongs_to :faq
  belongs_to :pseud
  has_many :support_tickets

  def by_owner?
    return true if
    self.support_tickets.join(:users) & User.join(:pseuds) & Pseud.where(:id => self.pseud.id) # was the ticket opened and commented on by the same user?
  end

  def byline
    if self.pseud_id.blank? # only owners of support tickets can add details without being logged in
      "Guest Support ticket owner"
    else
      prefix = self.support_response? ? "Support volunteer " : ""
      prefix + self.pseud.name
    end
  end

  before_create :check_for_support
  def check_for_support
    self.support_response = true if self.pseud.try(:support_volunteer)
    return true
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
