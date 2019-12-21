require 'game'
require 'aws-sdk-s3'

class UpdateResults
  def self.perform
    new.perform
  end

  def initialize(season: Season.current, client: Aws::S3::Client.new(region: 'us-east-1'))
    @season = season
    @client = client
  end

  def perform
    results = Game.games_for_season(season).map do |game|
      {
        name: game.bowl.name,
        location: [game.bowl.city, game.bowl.state].join(", "),
        time: game.game_time,
        visitor: {
          name: game.visitor.name,
          score: game.visitor_final_score.to_s
        },
        home: {
          name: game.home.name,
          score: game.home_final_score.to_s
        }
      }
    end

    client.put_object(
      bucket: "danhodge-cfb",
      key: "#{season.year}/results_#{season.year}.json",
      body: results.to_json
    )
  end

  private

  attr_reader :season, :client
end
