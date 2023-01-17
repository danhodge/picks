# game changes:
# 2021 tax slayer -> Rutgers replaced Texas A&M
# 2021 sun -> C. Mich replaced Miami  (C. Mich was originally scheduled to play in the Arizona Bowl against Boise State )

# game cancelled:
# 2021 arizona bowl - Boise withdrew, CMU switched to sun bowl
# 2021 military bowl - BC withdrew
# 2021 hawaii bowl - Hawaii withdrew
# 2021 holiday bowl - UCLA withdrew
# 2021 fenway bowl

class GameChange < ActiveRecord::Base
  belongs_to :game
  belongs_to :new_team, class_name: Team.name, foreign_key: :new_team_id
  belongs_to :previous_visiting_team, class_name: Team.name, foreign_key: :previous_visiting_team_id
  belongs_to :previous_home_team, class_name: Team.name, foreign_key: :previous_home_team_id

  validate :check_consistency

  def check_consistency
    if (previous_visiting_team && previous_home_team) || (!previous_visiting_team && !previous_home_team)
      errors[:previous_visiting_team_id] << "one and only one previous team must be set"
    elsif (previous_visiting_team && new_team != game.visiting_team)
      errors[:previous_visiting_team_id] << "the new team is not properly set as the visiting team"
    elsif (previous_home_team && new_team != game.home_team)
      errors[:previous_home_team_id] << "the new team is not properly set as the home team"
    end
  end
end
