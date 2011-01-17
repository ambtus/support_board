class SupportIdentity < ActiveRecord::Base
  has_one :user

  scope :official, :conditions => { :official => true }

  def byline
    self.user ? self.user.login : self.name
  end

end
