class ReleaseNote < ActiveRecord::Base
  has_many :code_tickets
  attr_protected :posted

  validates_presence_of :release

  # only support volunteers can create release notes
  before_validation(:on => :create) do
    raise SecurityError, "only volunteers can create release notes" if !User.current_user.try(:support_volunteer?)
  end

  scope :posted, :conditions => { :posted => true }
  scope :drafts, :conditions => { :posted => false }

  def post!
    raise "Couldn't deploy. Not logged in." unless User.current_user
    raise "Couldn't deploy. Not logged in as support admin." unless User.current_user.support_admin?
    self.update_attribute(:posted, true)
  end

  # SANITIZER stuff

  attr_protected :content_sanitizer_version
  def sanitized_content
    # FIXME add sanitizer library and change sanitized_summary to summary in views
    #sanitize_field self, :content
    content.html_safe
  end

end
