require 'game'
require 'aws-sdk-s3'

class ExportParticipants
  def initialize(season: Season.current, client: Aws::S3::Client.new(region: 'us-east-1'))
    @season = season
    @client = client
  end

  def perform
    participants = Participant.participants_for_season(season).map do |participant|
      {
        name: participant.nickname,
        tie_breaker: participant.tiebreaker,
        picks: participant.picks.sort_by { |pick| [pick.game.game_time, pick.game.id] }.map do |pick|
          {
            game_name: pick.game.bowl.name,
            team_name: pick.team.name,
            points: pick.points
          }
        end
      }
    end

    client.put_object(
      acl: "public-read",
      bucket: "danhodge-cfb",
      key: "#{season.year}/participants_#{season.year}.json",
      body: participants.to_json
    )
  end

  private

  attr_reader :season, :client
end
