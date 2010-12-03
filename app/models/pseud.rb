class Pseud < ActiveRecord::Base

  def to_param
    name
  end

end
