class ReleaseNote < ActiveRecord::Base
  has_many :code_tickets
  attr_protected :posted

  validates_presence_of :release

  scope :posted, :conditions => { :posted => true }
  scope :drafts, :conditions => { :posted => false }

end
