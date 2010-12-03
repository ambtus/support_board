class SupportDetail < ActiveRecord::Base
  belongs_to :support_ticket
  belongs_to :pseud

  scope :not_private, where(:private => false)
  scope :resolved, where(:resolved_ticket => true)

  def by_owner?
    return true if self.pseud_id.blank?  # only owners can add details without being logged in
    return false if !self.support_ticket.user # the ticket was opened by a guest but is being commented on by a user
    self.support_ticket.user.pseuds.include?(self.pseud) # was the ticket opened and commented on by the same user?
  end

  def byline
    if by_owner?
      "Ticket submitter"
    else
      prefix = self.support_response? ? "Support volunteer " : ""
      prefix + self.pseud.name
    end
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
