class Pseud < ActiveRecord::Base

  belongs_to :user

  def to_param
    name
  end

  before_save :fix_default
  def fix_default
    if self.is_default
      old = self.user.default_pseud
      old.update_attribute(:is_default, false) if old
    end
  end
end
