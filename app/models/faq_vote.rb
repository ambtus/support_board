class FaqVote < ActiveRecord::Base
  belongs_to :archive_faq
  belongs_to :support_ticket

end
