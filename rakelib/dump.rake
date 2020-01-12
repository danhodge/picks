require 'team'
require 'game'
require 'season'

namespace :dump do
  task common: "db:load_config" do
    result = {
      bowls: Bowl.all.map { |bowl| { name: bowl.name, city: bowl.city, state: bowl.state } },
      teams: Team.all.map { |team| { name: team.name } },
      users: User.all.map do |user|
        {
          email: user.email,
          uuid: user.uuid,
          user_type: user.user_type,
          password: user.password
        }
      end
    }

    File.open("common.json", "w") { |file| file << JSON.pretty_generate(result) }
  end

  task :season, [:year] => "db:load_config" do |_task, args|
    season = Season.find_by!(year: args[:year])

    games = Game.games_for_season(season).map do |game|
      result = {
        bowl: game.bowl.name,
        game_type: game.game_type,
        game_time: game.game_time.iso8601,
        visitor: {
          name: game.visitor.name,
          final_score: game.visitor_final_score,
        },
        home: {
          name: game.home.name,
          final_score: game.home_final_score,
        },
        point_spread: game.point_spread
      }

      { visitor: game.visitor.record(season), home: game.home.record(season) }.each do |key, record|
        next unless record
        result[key][:wins] = record.wins
        result[key][:losses] = record.losses
        result[key][:ranking] = record.ranking
      end

      result
    end

    participants = Participant.includes(:user, picks: [:game, :team]).where(season: season).map do |participant|
      {
        nickname: participant.nickname,
        uuid: participant.user && participant.user.uuid,
        tiebreaker: participant.tiebreaker,
        picks: participant.picks.map do |pick|
          {
            bowl: pick.game.bowl.name,
            team: pick.team.name,
            points: pick.points
          }
        end
      }
    end

    File.open("season_#{args[:year]}.json", "w") do |file|
      file << JSON.pretty_generate(games: games, participants: participants)
    end
  end
end
