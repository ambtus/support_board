class FaqNotification < ActiveRecord::Base
  belongs_to :faq

  def self.official
    where(:official => true)
  end
end
