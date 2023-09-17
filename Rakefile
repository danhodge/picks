require "sinatra/activerecord/rake"

$LOAD_PATH.unshift(File.expand_path('app', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/models', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/services', File.dirname(__FILE__)))

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # ignore error in envs that don't have rspec
end

namespace :db do
  task :load_config do
    require "./server"
  end
end
