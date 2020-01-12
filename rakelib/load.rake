require 'team'
require 'game'
require 'season'

namespace :load do
  task :common, [:path] =>  "db:load_config" do |_task, args|
    data = JSON.parse(File.read(args[:path]))
    ActiveRecord::Base.transaction do
      data["bowls"].each do |bowl|
        Bowl.where(name: bowl["name"]).first_or_create! do |b|
          b.city = bowl["city"]
          b.state = bowl["state"]
        end
      end

      data["teams"].each do |team|
        Team.where(name: team["name"]).first_or_create!
      end

      data["users"].each do |user|
        User.where(uuid: user["uuid"]).first_or_create! do |u|
          u.email = user["email"]
          u.user_type = user["user_type"]
          u.password = user["password"]
        end
      end
    end
  end

  task :season, [:path, :year] => "db:load_config" do |_task, args|
    data = JSON.parse(File.read(args[:path]))
    ActiveRecord::Base.transaction do
      season = Season.where(year: args[:year]).first_or_create!

      games = data["games"].map do |game|
        visitor = Team.find_by!(name: game["visitor"]["name"])
        home = Team.find_by!(name: game["home"]["name"])
        the_game = Game.where(season: season, bowl: Bowl.find_by!(name: game["bowl"])).first_or_create! do |g|
          g.game_type = game["game_type"]
          g.game_time = game["game_time"]
          g.visitor = visitor
          g.home = home
          g.point_spread = game["point_spread"]
        end

        if game["visitor"]["final_score"]
          FinalScore.where(game: the_game, team: visitor).first_or_create! do |fs|
            fs.points = game["visitor"]["final_score"]
          end
        end

        if game["home"]["final_score"]
          FinalScore.where(game: the_game, team: home).first_or_create! do |fs|
            fs.points = game["home"]["final_score"]
          end
        end

        if game["visitor"]["wins"]
          Record.where(season: season, team: visitor).first_or_create! do |rec|
            rec.wins = game["visitor"]["wins"]
            rec.losses = game["visitor"]["losses"]
            rec.ranking = game["visitor"]["ranking"]
          end
        end

        if game["home"]["wins"]
          Record.where(season: season, team: home).first_or_create! do |rec|
            rec.wins = game["home"]["wins"]
            rec.losses = game["home"]["losses"]
            rec.ranking = game["home"]["ranking"]
          end
        end

        the_game
      end

      data["participants"].each do |participant|
        part = Participant.where(season: season, nickname: participant["nickname"]).first_or_create! do |p|
          p.user_id = participant["uuid"]
          p.tiebreaker = participant["tiebreaker"]
        end

        participant["picks"].each do |pick|
          game = games.find { |g| g.bowl.name == pick["bowl"] }
          Pick.where(participant: part, game: game).first_or_create! do |p|
            p.team = game.teams.find { |team| team.name == pick["team"] }
            p.points = pick["points"]
          end
        end
      end
    end
  end
end
