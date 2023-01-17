class Game < ActiveRecord::Base
  GAME_TYPE_REGULAR = 1
  GAME_TYPE_SEMIFINAL = 2
  GAME_TYPE_CHAMPIONSHIP = 3

  # new statues: home team forfeit, visiting team forfeit
  GAME_STATUS_NORMAL = 1
  GAME_STATUS_CANCELLED = 2

  belongs_to :season
  belongs_to :bowl
  belongs_to :visitor, class_name: Team.name, foreign_key: :visiting_team_id
  belongs_to :home, class_name: Team.name, foreign_key: :home_team_id
  has_many :final_scores
  has_many :picks

  validates :game_time, presence: true
  validates :game_type, inclusion: { in: [GAME_TYPE_REGULAR, GAME_TYPE_SEMIFINAL, GAME_TYPE_CHAMPIONSHIP] }
  validates :game_status, inclusion: { in: [GAME_STATUS_NORMAL, GAME_STATUS_CANCELLED] }
  validates :bowl_id, uniqueness: { scope: :season_id }

  delegate :name, to: :bowl, allow_nil: false

  def self.games_for_season(season)
    where(season: season).includes(:bowl, { visitor: :records }, { home: :records }, { final_scores: [:game, :team] }).order(:game_time, :id)
  end

  def teams
    [visitor, home]
  end

  def completed?
    final_scores.count == 2 || game_status == GAME_STATUS_CANCELLED
  end

  def visitor_final_score
    final = final_scores.find { |score| score.team == visitor }
    final && final.points
  end

  def home_final_score
    final = final_scores.find { |score| score.team == home }
    final && final.points
  end

  def favored_team
    if point_spread && (point_spread < 0)
      visitor
    else
      # if the point_spread is unknown or even, default the home team as the favorite
      home
    end
  end

  def abs_point_spread
    return 0 unless point_spread

    point_spread.abs.round(1)
  end
end
