class Participant < ActiveRecord::Base
  belongs_to :season
  belongs_to :user
  has_many :picks

  validates :nickname, :tiebreaker, presence: true

  def self.ensure!(user:, nickname:, tiebreaker: 0, season: Season.current)
    where(user: user, season: season).first_or_create! do |participant|
      participant.nickname = nickname
      participant.tiebreaker = tiebreaker
    end
  end

  def validate_picks!
    raise "Invalid picks" unless (picks.count == season.games.count) && (picks.map(&:points).sort == (1..season.games.count).to_a)
  end
end
