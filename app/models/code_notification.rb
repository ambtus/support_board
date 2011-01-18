class CodeNotification < ActiveRecord::Base
  belongs_to :code_ticket
  validates :email, :email_veracity => {:on => :create}

  def self.official
    where(:official => true)
  end
end
