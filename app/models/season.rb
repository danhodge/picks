class Season < ActiveRecord::Base
  has_many :games
  has_many :participants

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

  def name
    [year, (year + 1) % 2000].map(&:to_s).join("-")
  end

  def total_points
    (1..games.count).sum
  end
end
