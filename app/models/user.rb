class User < ActiveRecord::Base

  acts_as_authentic
  acts_as_authorized_user
  acts_as_authorizable
  has_and_belongs_to_many :roles
  belongs_to :support_identity

  # Allows other models to get the current user with User.current_user
  cattr_accessor :current_user

  def support_identity_with_create
    support_identity_without_create || SupportIdentity.create(:name => self.login, :user => self)
  end
  alias_method_chain :support_identity, :create

  def to_param
    login
  end

  # Is this user an authorized support volunteer?
  def support_volunteer?
    has_role?(:support_volunteer)
  end

  # Set support volunteer role for this user and log change
  def support_volunteer=(should_be_support_volunteer)
    case should_be_support_volunteer
    when "1"
      set_role('support_volunteer', true)
      # set the support identity as official
      self.support_identity.update_attribute(:official, true)
    else
      set_role('support_volunteer', false)
      # remove the official designation from the support identity
      self.support_identity.update_attribute(:official, false)
    end
  end

  # Is this user an authorized support admin?
  def support_admin?
    has_role?(:support_admin)
  end

  # Set support admin role for this user and log change
  def support_admin=(should_be_support_admin)
    set_role('support_admin', should_be_support_admin == '1')
    # if adding as a support admin, add as a support volunteer as well
    # but don't remove the support volunteer role if removing the admin role
    # if you want to do that as well, it needs to be done in a separate step
    self.support_volunteer = '1' if (should_be_support_admin == '1' && !self.support_volunteer?)
  end

end
