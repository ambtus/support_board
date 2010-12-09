class ArchiveFaq < ActiveRecord::Base

  # used in lists
  def name
    "##{self.id.to_s}: #{self.title}"
  end

end
