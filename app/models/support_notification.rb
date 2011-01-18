class SupportNotification < ActiveRecord::Base
  belongs_to :support_ticket
  validates :email, :email_veracity => {:on => :create}

  def self.official
    where(:official => true)
  end
end
