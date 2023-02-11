# game changes:
# 2021 tax slayer -> Rutgers replaced Texas A&M
# 2021 sun -> C. Mich replaced Miami  (C. Mich was originally scheduled to play in the Arizona Bowl against Boise State ) - (WSU wins)
#   WSU v Miami   <-- orig
#   WSU v CMU     <-- change
#   CMU over WSU  <-- final score
#   points to WSU because has game change & WSU not changed
#   if both teams changed, no points would be rewarded because no one could have picked either team
#
# GameOutcome
#   completed: true or false
#   final_score: [[winner, points], [loser, points]]
#   points_awarded_to: team | nil
#   reason: normal, cancelled, forfeit, team_switch, double_team_switch

# game cancelled:
# 2021 arizona bowl - Boise withdrew, CMU switched to sun bowl (CMU wins)
# 2021 military bowl - BC withdrew
# 2021 hawaii bowl - Hawaii withdrew
# 2021 holiday bowl - UCLA withdrew
# 2021 fenway bowl

class GameChange < ActiveRecord::Base
  belongs_to :game
  belongs_to :new_team, class_name: Team.name, foreign_key: :new_team_id
  belongs_to :previous_visiting_team, class_name: Team.name, foreign_key: :previous_visiting_team_id
  belongs_to :previous_home_team, class_name: Team.name, foreign_key: :previous_home_team_id

  enum status: %i[pending accepted rejected]

  validate :check_consistency
  validates :status, inclusion: { in: statuses.keys }

  def accept_change!
    transaction do
      if previous_visiting_team
        game.visiting_team_id = new_team_id
      else
        game.home_team_id = new_team_id
      end
      game.save!
      accepted!
    end
  end

  private

  def check_consistency
    if (previous_visiting_team && previous_home_team) || (!previous_visiting_team && !previous_home_team)
      errors.add(:previous_visiting_team_id, "one and only one previous team must be set")
    elsif accepted? && (previous_visiting_team && new_team != game.visitor)
      errors.add(:previous_visiting_team_id, "the new team is not properly set as the visiting team")
    elsif accepted? && (previous_home_team && new_team != game.home)
      errors.add(:previous_home_team_id, "the new team is not properly set as the home team")
    end
  end
end
