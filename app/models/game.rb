class Game < ActiveRecord::Base
  GAME_TYPE_REGULAR = 1
  GAME_TYPE_SEMIFINAL = 2
  GAME_TYPE_CHAMPIONSHIP = 3

  belongs_to :season
  belongs_to :bowl
  belongs_to :visitor, class_name: Team.name, foreign_key: :visiting_team_id
  belongs_to :home, class_name: Team.name, foreign_key: :home_team_id

  validates :game_time, presence: true
  validates :game_type, inclusion: { in: [GAME_TYPE_REGULAR, GAME_TYPE_SEMIFINAL, GAME_TYPE_CHAMPIONSHIP] }
  validates :bowl_id, uniqueness: { scope: :season_id }

  def self.games_for_season(season)
    where(season: season).includes(:bowl, :visitor, :home).order(:game_time, :id)
  end
end
