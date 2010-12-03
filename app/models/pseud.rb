class Pseud < ActiveRecord::Base

  belongs_to :user

  def to_param
    name
  end

end
