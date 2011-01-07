class SupportIdentity < ActiveRecord::Base
  has_one :user

  scope :official, :conditions => { :official => true }
end
