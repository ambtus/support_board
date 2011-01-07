class Faq < ActiveRecord::Base
  has_many :faq_details
  has_many :faq_votes

  # don't save new empty details
  accepts_nested_attributes_for :faq_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  attr_protected :posted

  default_scope :order => 'position ASC'

  # used in lists
  def name
    "#{self.position.to_s}: #{self.title}"
  end

  def vote_count
    faq_votes.sum(:vote)
  end

  def post!
    raise "Couldn't post. Not logged in." unless User.current_user
    raise "Couldn't post. Not logged in as support admin." unless User.current_user.support_admin?
    self.update_attribute(:posted, true)
  end

  before_create :set_owner
  def set_owner
    raise "Couldn't create. Not logged in." unless User.current_user
    raise "Couldn't post. Not logged in as support volunteer." unless User.current_user.support_volunteer?
    self.user_id = User.current_user
  end

  before_create :set_position
  def set_position
    self.position = Faq.count + 1 unless self.position
  end

end
