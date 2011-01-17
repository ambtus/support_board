class SupportDetail < ActiveRecord::Base
  belongs_to :support_ticket
  belongs_to :support_identity

  scope :resolved, where(:resolved_ticket => true)
  scope :system_log, where(:system_log => true)

  def self.public_comments
    where(:private => false).where(:system_log => false)
  end

  def by_owner?
    return false if self.support_response # official support response
    return true if self.support_identity.blank?  # only owners can add details without being logged in
    return false if !self.support_ticket.user # the ticket was opened by a guest but is being commented on by a user
    self.support_ticket.user.support_identity == self.support_identity # was the ticket opened and commented on by the same user?
  end

  def show_username?
    !self.support_ticket.anonymous? && self.support_identity_id
  end

  def byline_name
    if by_owner?
      self.show_username? ? self.support_identity.name : "ticket owner"
    else
      self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
    end
  end

  def byline
    date = self.updated_at.to_s(:short)
    name = self.byline_name
    system = self.system_log? ? "" : " wrote"
    accepted = self.resolved_ticket? ? " (accepted)" : ""
    private = self.private? ? " [private]" : ""
    "[#{date}] #{name}#{system}#{accepted}#{private}"
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
