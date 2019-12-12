require "sinatra/activerecord/rake"

$LOAD_PATH.unshift(File.expand_path('app', File.dirname(__FILE__)))
$LOAD_PATH.unshift(File.expand_path('app/models', File.dirname(__FILE__)))

namespace :db do
  task :load_config do
    require "./server"
  end
end
