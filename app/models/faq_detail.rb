class FaqDetail < ActiveRecord::Base
  belongs_to :faq
  belongs_to :support_identity

  scope :system_log, where(:system_log => true)

  def self.public_comments
    where(:private => false).where(:system_log => false)
  end

  def byline
    if self.support_identity_id.blank? # only owners of support tickets can add details to faqs without a support identity
      name = "support ticket owner"
      system = " wrote"
    else
      name = self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
      system = self.system_log? ? "" : " wrote"
    end
    private = self.private? ? " [private]" : ""
    "[#{self.updated_at.to_s(:short)}] #{name}#{system}#{private}"
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
