$LOAD_PATH.unshift(File.expand_path('app', __FILE__))
$LOAD_PATH.unshift(File.expand_path('models', __FILE__))

require 'update_scores'
require 'clockwork'
require 'fileutils'

module Clockwork
  handler do |job|
    puts "Running job: #{job}"
  end

  every(1.minute, 'heartbeat') do
    heartbeat_file = File.expand_path('heartbeat', __FILE__)
    FileUtils.touch(heartbeat_file)
  end

  every(10.minutes, 'update_scores') do
    UpdateScores.perform
  end
end
