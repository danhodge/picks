class Pick < ActiveRecord::Base
  belongs_to :participant
  belongs_to :game
  belongs_to :team
  has_one :season, through: :game

  enum status: %i[pending correct incorrect]

  validates :points, presence: true
  validates :game_id, uniqueness: { scope: [:participant_id] }
  validate :check_consistency

  scope :completed, -> { where.not(status: :pending) }

  private

  def check_consistency
    errors.add(:season_id, "Participant/Game Season mismatch") unless participant.season == game.season

    if game.game_type == Game::GAME_TYPE_CHAMPIONSHIP
      semi_finalist_ids = Game
                            .where(season: season, game_type: Game::GAME_TYPE_SEMIFINAL)
                            .flat_map { |game| [game.visitor, game.home] }
                            .map(&:id)

      unless semi_finalist_ids.include?(team_id)
        errors.add(:team_id, "Invalid team: #{team.try(:id)}, #{game.visiting_team_id}, #{game.home_team_id}")
      end
    else
      errors.add(:team_id, "Invalid team: #{team.try(:id)}, #{game.visiting_team_id}, #{game.home_team_id}") unless (game.visitor == team || game.home == team)
    end
  end
end
