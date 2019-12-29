$LOAD_PATH.unshift(File.expand_path('app', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/models', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/services', File.dirname(__FILE__)))

require 'sinatra/activerecord'
require 'models'
require 'backup_db'
require 'update_scores'
require 'clockwork'
require 'fileutils'

module Clockwork
  handler do |job|
    puts "Running job: #{job}"
  end

  every(1.minute, 'heartbeat') do
    heartbeat_file = File.expand_path('heartbeat', File.dirname(__FILE__))
    FileUtils.touch(heartbeat_file)
  end

  every(10.minutes, 'update_scores') do
    UpdateScores.perform
  end

  every(1.hour, 'backup_db') do
    BackupDB.perform
  end
end
