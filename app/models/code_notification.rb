class CodeNotification < ActiveRecord::Base
  belongs_to :code_ticket

  def self.official
    where(:official => true)
  end
end
