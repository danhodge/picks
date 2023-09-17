require 'score'

class MergeTeams
  def initialize(src_team_id, dest_team_id)
    @src_team_id = src_team_id
    @dest_team_id = dest_team_id
  end

  def perform
    ActiveRecord::Base.transaction do
      FinalScore.where(team_id: src_team_id).update_all(team_id: dest_team_id)
      GameChange.where(new_team_id: src_team_id).update_all(new_team_id: dest_team_id)
      GameChange.where(previous_visiting_team_id: src_team_id).update_all(previous_visiting_team_id: dest_team_id)
      GameChange.where(previous_home_team_id: src_team_id).update_all(previous_home_team_id: dest_team_id)
      Game.where(visiting_team_id: src_team_id).update_all(visiting_team_id: dest_team_id)
      Game.where(home_team_id: src_team_id).update_all(home_team_id: dest_team_id)
      Pick.where(team_id: src_team_id).update_all(team_id: dest_team_id)
      Record.where(team_id: src_team_id).update_all(team_id: dest_team_id)
      Score.where(team_id: src_team_id).update_all(team_id: dest_team_id)
      Team.find(src_team_id).destroy
    end
  end

  private
  
  attr_reader :src_team_id, :dest_team_id
end
