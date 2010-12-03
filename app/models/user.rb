class User < ActiveRecord::Base

  acts_as_authentic

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
end
