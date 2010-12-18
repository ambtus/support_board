class FaqVote < ActiveRecord::Base
  belongs_to :faq
  belongs_to :support_ticket

end
