require 'sums_up'

GameOutcome = SumsUp.define(
  :incomplete, 
  :cancelled,
  :tied,
  completed: [:game], 
  completed_with_change: [:game], 
  completed_with_changes: [:game], 
  forfeited: [:game]) do

  def high_score_team(game)
    game.visitor_final_score > game.home_final_score ? game.visitor : game.home
  end

  def low_score_team(game)
    game.visitor_final_score < game.home_final_score ? game.visitor : game.home
  end

  def unchanged_teams(game)
    if game.accepted_game_changes.empty?
      game.teams
    else
      game.teams - game.accepted_game_changes.map(&:new_team)
    end
  end

  def winner
    match do |m|
      m.incomplete nil
      m.tied nil 
      m.completed(&method(:high_score_team))
      m.completed_with_change(&method(:high_score_team))
      m.completed_with_changes(&method(:high_score_team))
      m.forfeited nil
      m.cancelled nil    
    end
  end

  def loser
    match do |m|
      m.incomplete nil
      m.tied nil 
      m.completed(&method(:low_score_team))
      m.completed_with_change(&method(:low_score_team))
      m.completed_with_changes(&method(:low_score_team))
      m.forfeited nil
      m.cancelled nil    
    end
  end

  def points_awarded_to
    match do |m|
      m.incomplete nil
      m.tied nil 
      m.completed(&method(:high_score_team))
      m.completed_with_change { |game| unchanged_teams(game).first }
      m.completed_with_changes nil
      m.forfeited { |game| game.home_forfeit? ? game.visitor : game.home }
      m.cancelled nil    
    end
  end
end