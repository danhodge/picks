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
      Tempfile.create("backup") do |tmp_file|
        `sqlite3 #{db["file"]} .dump > #{tmp_file}`
        hour = "%02d" % Time.now.hour
        key = "#{season.year}/backups/db_#{ENV["RACK_ENV"]}_#{hour}.sql"
        resp = client.put_object(
          bucket: "danhodge-cfb",
          key: key,
          body: File.read(tmp_file)
        )
        puts "Backed up database to #{key} - #{resp}"
      end
    else
      puts "No main database found, not backing up"
    end
  end

  private

  attr_reader :season, :client
end
