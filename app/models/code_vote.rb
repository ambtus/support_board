class CodeVote < ActiveRecord::Base
  belongs_to :code_ticket
  belongs_to :user

end
