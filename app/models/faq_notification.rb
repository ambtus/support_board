class FaqNotification < ActiveRecord::Base
  belongs_to :faq
  validates :email, :email_veracity => {:on => :create}

  def self.official
    where(:official => true)
  end
end
