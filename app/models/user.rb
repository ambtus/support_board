class User < ActiveRecord::Base

  acts_as_authentic
  acts_as_authorized_user
  acts_as_authorizable
  has_and_belongs_to_many :roles

  def to_param
    login
  end

  def activate
    self.update_attribute(:activated_at, Time.now.utc)
  end

  has_many :pseuds
  accepts_nested_attributes_for :pseuds, :allow_destroy => true

  before_create :build_default_pseud
  def build_default_pseud
    self.pseuds.build(:name => self.login, :is_default => true)
  end

  def default_pseud
    self.pseuds.where(:is_default => true).first
  end

  # get the pseud marked for support work
  def support_pseud
    self.pseuds.where(:support_volunteer => true).first
  end

  # Is this user an authorized support volunteer?
  def support_volunteer
    has_role?(:support_volunteer)
  end

  # Set support volunteer role for this user and log change
  def support_volunteer=(should_be_support_volunteer)
    set_role('support_volunteer', should_be_support_volunteer == '1')
  end

  # Is this user an authorized support admin?
  def support_admin
    has_role?(:support_admin)
  end

  # Set support admin role for this user and log change
  def support_admin=(should_be_support_admin)
    set_role('support_admin', should_be_support_admin == '1')
    # if adding as a support admin, add as a support volunteer as well
    # but don't remove the support volunteer role if removing the admin role
    set_role('support_volunteer', should_be_support_admin == '1') if should_be_support_admin == '1'
  end

end
