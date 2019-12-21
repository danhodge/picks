class Score < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  validates :points, :quarter, :time_remaining_seconds, presence: true
  validate :check_consistency

  private

  def check_consistency
    if team && game && !game.teams.include?(team)
      errors[:team_id] << "Invalid team (#{team.id}) for game (#{game.id})"
    end
  end
end
