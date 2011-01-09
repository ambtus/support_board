class FaqDetail < ActiveRecord::Base
  belongs_to :faq
  belongs_to :support_identity

  def byline
    if self.support_identity_id.blank? # only owners of support tickets can add details to faqs without a support identity
      name = "support ticket owner"
      system = " wrote"
    else
      name = self.support_identity.name + (self.support_response? ? " (volunteer)" : "")
      system = self.system_log? ? "" : " wrote"
    end
    "[#{self.updated_at.to_s(:short)}] #{name}#{system}"
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    sanitize_field self, :content
  end

end
