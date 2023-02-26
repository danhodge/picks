require 'game'
require 'aws-sdk-s3'

class ExportParticipants
  def self.perform(season)
    new(season: season).perform
  end

  def initialize(season: Season.current, client: Aws::S3::Client.new(region: 'us-east-1'))
    @season = season
    @client = client
  end

  def build_participants
    Participant.participants_for_season(season).each_with_object({}) do |participant, participants|
      participants[participant.id] = {
        name: participant.nickname,
        tiebreaker: participant.tiebreaker,
        picks: participant.picks.each_with_object({}) do |pick, picks|
          picks[pick.game.id] = {
            team_id: pick.team.id,
            points: pick.points
          }
        end
      }
    end
  end

  def build_games
    Game.games_for_season(season).each_with_object({}) do |game, games|
      games[game.id] = {
        name: game.bowl.name,
        time: game.game_time.iso8601,
        location: [game.bowl.city, game.bowl.state].compact.join(", "),
        visiting_team_id: game.visiting_team_id,
        home_team_id: game.home_team_id
      }
    end
  end

  def build_teams
    Team.all.map { |team| [team.id, team.name] }.to_h
  end

  def perform
    participants = {
      participants: build_participants,
      games: build_games,
      teams: build_teams
    }

    client.put_object(
      acl: "public-read",
      bucket: "danhodge-cfb",
      key: "#{ENV['RACK_ENV']}/#{season.year}/participants.json",
      body: participants.to_json
    )
  end

  private

  attr_reader :season, :client
end
