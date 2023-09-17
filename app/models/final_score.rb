class FinalScore < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  validates :points, presence: true
  validate :check_consistency

  private

  def check_consistency
    if team && game && !game.teams.include?(team)
      errors.add(:team_id, "Invalid team (#{team.id}) for game (#{game.id})")
    end
  end
end
