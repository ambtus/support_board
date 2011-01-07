class SupportDetail < ActiveRecord::Base
  belongs_to :support_ticket
  belongs_to :support_identity

  scope :not_private, where(:private => false)
  scope :resolved, where(:resolved_ticket => true)

  def by_owner?
    return true if self.support_identity.blank?  # only owners can add details without being logged in
    return false if !self.support_ticket.user # the ticket was opened by a guest but is being commented on by a user
    self.support_ticket.user.support_identity == self.support_identity # was the ticket opened and commented on by the same user?
  end

  def byline_name
    if by_owner?
      (self.support_ticket.display_user_name? && self.support_identity_id) ? self.support_identity.name : "ticket owner"
    else
      self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
    end
  end

  def byline
    date = self.updated_at.to_s(:short)
    name = self.byline_name
    system = self.system_log? ? "" : " wrote"
    accepted = self.resolved_ticket? ? " (accepted)" : ""
    "[#{date}] #{name}#{system}#{accepted}"
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
