class ArchiveFaq < ActiveRecord::Base
  has_many :faq_details

  # don't save new empty details
  accepts_nested_attributes_for :faq_details, :reject_if => proc { |attributes|
                                          attributes['content'].blank? && attributes['id'].blank? }

  attr_protected :posted

  # used in lists
  def name
    "#{self.position.to_s}: #{self.title}"
  end

end
