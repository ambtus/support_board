class SupportNotification < ActiveRecord::Base
  belongs_to :support_ticket

  def self.official
    where(:official => true)
  end
end
