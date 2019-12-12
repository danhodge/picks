class Season < ActiveRecord::Base
  validates :year, presence: true

  def self.current
    now = Time.now
    year = if now.month == 12
             now.year
           else
             now.year - 1
           end

    Season.where(year: year).first_or_create!
  end
end
