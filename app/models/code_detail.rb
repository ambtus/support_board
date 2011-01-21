class CodeDetail < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :support_identity

  scope :resolved, where(:resolved_ticket => true)
  scope :system_log, where(:system_log => true)
  scope :visible_to_all, where(:private => false)
  scope :written_comments, where(:system_log => false)

  # support_identity name, with volunteer designation if support response
  def byline
    parens = self.support_response? ? " (volunteer)" : ""
    self.support_identity.name + parens
  end

  # concise representation of all info except content
  def info
    date = self.updated_at.to_s(:short)
    wrote = self.system_log? ? "" : " wrote"
    private = self.private? ? " [private]" : ""
    "[#{date}] #{self.byline}#{wrote}#{private}"
  end

  # SANITIZER stuff
  attr_protected :content_sanitizer_version
  def sanitized_content
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :content
    content.html_safe
  end

end
