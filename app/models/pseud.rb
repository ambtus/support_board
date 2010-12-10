class Pseud < ActiveRecord::Base

  belongs_to :user

  def to_param
    name
  end

  before_save :make_unique_default
  def make_unique_default
    if self.is_default
      old = self.user.default_pseud
      return unless old
      return if old == self
      old.update_attribute(:is_default, false)
    end
  end

  before_save :make_unique_support
  def make_unique_support
    if self.support_volunteer
      old = self.user.support_pseud
      return unless old
      return if old == self
      old.update_attribute(:support_volunteer, false)
    end
  end
end
