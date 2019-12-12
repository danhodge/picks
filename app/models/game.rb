class Game < ActiveRecord::Base
  belongs_to :season
  belongs_to :bowl
  belongs_to :visitor, class_name: Team.name, foreign_key: :visiting_team_id
  belongs_to :home, class_name: Team.name, foreign_key: :home_team_id

  validates :point_spread, :game_time, presence: true
end
