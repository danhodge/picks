require 'models'

namespace :manual do
  task :final_score, [:game, :team, :points, :season] => "db:load_config" do |_task, args|
    raise "Must specify game, team, and points" unless args.key?(:game) && args.key?(:team) && args.key?(:points)

    Season.transaction do
      season = args.key?(:season) ? Season.find_by!(year: args[:season]) : Season.current
      bowl = Bowl.find_by!(name: Bowl.normalize_name(args[:game], season: season))
      game = Game.find_by!(season: season, bowl: bowl)
      team = Team.find_by!(name: Team.normalize_name(args[:team]))

      FinalScore.where(game: game, team: team).first_or_create!(points: args[:points])
      if game.reload.final_scores.count == 2
        game.finished!
      end
    end  
  end
end