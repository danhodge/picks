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
    errors[:team_id] << "Invalid team: #{team.try(:id)}, #{game.visiting_team_id}, #{game.home_team_id}" unless (game.visitor == team || game.home == team)
  end
end
