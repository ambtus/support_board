class SupportIdentity < ActiveRecord::Base
  has_one :user

  scope :official, :conditions => { :official => true }

  def matched?
    self.user
  end

  def byline
    if self.matched?
      self.user.login
    else
      self.name
    end
  end
end
