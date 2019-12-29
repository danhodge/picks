require 'time'
require 'aws-sdk-s3'
require 'season'

class BackupDB
  def self.perform
    new.perform
  end

  def initialize(season: Season.current, client: Aws::S3::Client.new(region: 'us-east-1'))
    @season = season
    @client = client
  end

  def perform
    db = ActiveRecord::Base.connection.execute("PRAGMA database_list").find { |d| d["name"] == "main" }

    if db
      backup = "/tmp/db.bak"
      `sqlite3 #{db["file"]} .dump > #{backup}`
      hour = "%02d" % Time.now.hour
      key = "#{season.year}/backups/db_#{ENV["RACK_ENV"]}_#{hour}.sql"
      resp = client.put_object(
        bucket: "danhodge-cfb",
        key: key,
        body: File.read(backup)
      )
      puts "Backed up database to #{key} - #{resp}"
    else
      puts "No main database found, not backing up"
    end
  end

  private

  attr_reader :season, :client
end
