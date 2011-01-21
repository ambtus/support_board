class CodeVote < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :user

  def move_to_ticket(new)
    raise "trying to move to current" if self.code_ticket == new
    if new.code_votes.where(:user_id => self.user_id).first
      self.destroy
    else
      self.update_attribute(:code_ticket_id, new.id)
    end
  end
end
