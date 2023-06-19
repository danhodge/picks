require 'game'
require 'aws-sdk-s3'

class UpdateSeasons
  def self.perform(relation: Season.all)
    new(relation).perform
  end

  def initialize(relation, client: Aws::S3::Client.new(region: 'us-east-1'))
    @client = client
    @relation = relation
  end

  def build_seasons
    relation.order(:year).map do |season|
      next unless season.in_progress? || season.completed?
      next if season.year < 2017  # pre-2017 not working due to missing scores data

      path = "#{ENV['RACK_ENV']}/#{season.year}"
      {
        name: season.name, 
        path: season.year.to_s, 
        results_url: "https://danhodge-cfb.s3.amazonaws.com/#{path}/results.json",
        participants_url: "https://danhodge-cfb.s3.amazonaws.com/#{path}/participants.json"
      }
    end.compact
  end

  def perform
    key = "#{ENV['RACK_ENV']}/seasons.json"
    resp = client.put_object(
      acl: "public-read",
      bucket: "danhodge-cfb",
      key: key,
      body: build_seasons.to_json
    )
    puts "Updated s3://danhodge-cfb/#{key} - #{resp}"
  end

  private

  attr_reader :relation, :client
end
