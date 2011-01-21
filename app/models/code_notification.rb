class CodeNotification < ActiveRecord::Base
  belongs_to :code_ticket
  validates :email, :email_veracity => {:on => :create}

  def self.official
    where(:official => true)
  end

  def move_to_ticket(new)
    raise "trying to move to current" if self.code_ticket == new
    if new.code_notifications.where(:email => self.email).first
      self.destroy
    else
      self.update_attribute(:code_ticket_id, new.id)
    end
  end

end
