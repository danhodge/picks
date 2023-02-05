require 'models'

def resolve(args)
  season = args.key?(:season) ? Season.find_by!(year: args[:season]) : Season.current
  bowl = Bowl.find_by!(name: Bowl.normalize_name(args[:game], season: season))
  game = Game.find_by!(season: season, bowl: bowl)
  team = Team.find_by!(name: Team.normalize_name(args[:team]))

  [game, team]
end

namespace :manual do
  task :final_score, [:game, :team, :points, :season] => "db:load_config" do |_task, args|
    raise "Must specify game, team, and points" unless args.key?(:game) && args.key?(:team) && args.key?(:points)

    Season.transaction do
      game, team = resolve(args)

      FinalScore.where(game: game, team: team).first_or_create!(points: args[:points])
      if game.reload.final_scores.count == 2
        game.finished!
      end
    end  
  end

  task :record_abandonment, [:game, :team, :season] => "db:load_config" do |_task, args|
    raise "Must specify game and team" unless args.key?(:game) && args.key?(:team)

    Season.transaction do
      game, team = resolve(args)
      raise "Game is not in an abandonable state" unless game.cancelled? || game.missing?

      game.abandoned!
    end  
  end

  task :record_forfeit, [:game, :team, :season] => "db:load_config" do |_task, args|
    raise "Must specify game and team" unless args.key?(:game) && args.key?(:team)

    Season.transaction do
      game, team = resolve(args)
      raise "Game is not in a forfeitable state" unless game.cancelled? || game.missing?

      if team == game.visitor
        game.visitor_forfeit!
      elsif team == game.home
        game.home_forfeit!
      else
        raise "#{team.name} was not a contestant in the #{game.bowl.name} bowl"
      end
    end  
  end

  task :accept_change, [:game, :team, :season] => "db:load_config" do |_task, args|
    raise "Must specify game and team" unless args.key?(:game) && args.key?(:team)

    Season.transaction do
      game, team = resolve(args)

      change = GameChange.find_by!(game: game, new_team: team)
      change.accept_change!
    end
  end
end