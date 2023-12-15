require 'generate_picks'

def merge_team 
  ActiveRecord::Base.transaction do
    usf = Team.find_by!(name: "USF")
    south_florida = Team.find_by!(name: "South Florida")

    FinalScore.where(team_id: usf.id).update_all(team_id: south_florida.id)
    Game.where(home_team_id: usf.id).update_all(home_team_id: south_florida.id)
    Game.where(visiting_team_id: usf.id).update_all(visiting_team_id: south_florida.id)
    Pick.where(team_id: usf.id).update_all(team_id: south_florida.id)
    Record.where(team_id: usf.id).update_all(team_id: south_florida.id)
    Score.where(team_id: usf.id).update_all(team_id: south_florida.id)
    FinalScore.where(team_id: usf.id).update_all(team_id: south_florida.id)
    usf.destroy
  end
end  

class ESPNPicks
  def self.generate(csv_path, espn_json_path, tie_breaker, season: Season.current)
    picks_by_game = 
      GeneratePicks.new(season, File.read(csv_path)).
        compute.
        map { |game, team, conf| [game, [team, conf]] }.
        to_h

    picks = JSON.parse(File.read(espn_json_path)).map do |game_info|
      game = Game.includes(:bowl).find_by!(season: season, bowls: { name: Bowl.normalize_name(game_info["name"])})
      pick = picks_by_game[game]

      prop_id =
        if Bowl.championship?(game.bowl.name)
          visitors = game_info["visitor"]["name"].split("/").map { |name| Team.find_by!(name: Team.normalize_name(name)) }
          homes = game_info["home"]["name"].split("/").map { |name| Team.find_by!(name: Team.normalize_name(name)) }

          if visitors.all? { |team| [pick[0].winner_of.visitor, pick[0].winner_of.home].include?(team) }
            game_info["visitor"]["id"]
          elsif home.all? { |team| [pick[0].winner_of.visitor, pick[0].winner_of.home].include?(team) }
            game_info["home"]["id"]
          else
            raise "Team Not Found: #{pick[0].display_name}, #{game_info}"
          end
        else
          visitor = Team.find_by!(name: Team.normalize_name(game_info["visitor"]["name"]))
          home = Team.find_by!(name: Team.normalize_name(game_info["home"]["name"]))  

          if pick[0] == visitor
            game_info["visitor"]["id"]
          elsif pick[0] == home
            game_info["home"]["id"]
          else
            raise "Team Not Found: #{pick[0].display_name}, #{game_info}"
          end
        end

      {
        "confidenceScore": pick[1],
        "outcomesPicked": [
          {
            "outcomeId": prop_id,
            "result": "UNDECIDED"
          }
        ],
        "propositionId": game_info["id"]
      }
    end

    File.open("espn_picks_#{season.year}.json", "w") do |f| 
      f.puts(JSON.pretty_generate(picks: picks, edition: "espn-en"))
    end
  end
end