class Participant < ActiveRecord::Base
  belongs_to :season
  belongs_to :user
  has_many :picks

  validates :nickname, :tiebreaker, presence: true

  def self.ensure!(user, season: Season.current)
    transaction do
      participant = where(user: user, season: season).first_or_create! do |p|
        p.nickname ||= user.email.split("@").first
        p.tiebreaker ||= 1
      end

      if participant.picks.empty?
        season.games.each_with_index do |game, i|
          Pick.create!(season: season, participant: participant, game: game, team: game.visitor, points: i + 1)
        end
      end

      participant
    end
  end
end
