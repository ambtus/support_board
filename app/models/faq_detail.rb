class FaqDetail < ActiveRecord::Base
  belongs_to :faq
  belongs_to :support_identity
  has_many :support_tickets

  def by_owner?
    return true if
    self.support_tickets.join(:users) & User.join(:support_identities) & SupportIdentity.where(:id => self.support_identity_id) # was the ticket opened and commented on by the same user?
  end

  def byline
    if self.support_identity_id.blank? # only owners of support tickets can add details without being logged in
      "Guest Support ticket owner"
    else
      prefix = self.support_response? ? "Support volunteer " : ""
      prefix + self.support_identity.name
    end
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
