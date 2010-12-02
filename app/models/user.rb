class User < ActiveRecord::Base

  acts_as_authentic 

  def to_param
    login
  end

  def activate
    self.update_attribute(:activated_at, Time.now.utc)
  end

end
