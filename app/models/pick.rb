class Pick < ActiveRecord::Base
  belongs_to :season
  belongs_to :participant
  belongs_to :game
  belongs_to :team

  validates :points, presence: true
  validates :game_id, uniqueness: { scope: [:season_id, :participant_id] }
  validate :check_consistency

  private

  def check_consistency
    errors[:season_id] << "Participant/Season mismatch" unless participant.season == season
    errors[:game_id] << "Game/Season mismatch" unless game.season == season

    if game.game_type == Game::GAME_TYPE_CHAMPIONSHIP
      semi_finalist_ids = Game
                            .where(season: season, game_type: Game::GAME_TYPE_SEMIFINAL)
                            .flat_map { |game| [game.visitor, game.home] }
                            .map(&:id)

      unless semi_finalist_ids.include?(team_id)
        errors[:team_id] << "Invalid team: #{team.try(:id)}, #{game.visiting_team_id}, #{game.home_team_id}"
      end
    else
      errors[:team_id] << "Invalid team: #{team.try(:id)}, #{game.visiting_team_id}, #{game.home_team_id}" unless (game.visitor == team || game.home == team)
    end
  end
end
