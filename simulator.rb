require 'sinatra/base'
require 'sinatra/activerecord'
require 'simulator_app'

class Simulator < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  set :root, File.dirname(__FILE__)
  set :public_folder, File.expand_path("simulator_public", File.dirname(__FILE__))
  set :views, File.expand_path('views/simulator', File.dirname(__FILE__))
  set :static, true
  set :static_cache_control, [:public, max_age: 1]

  use ::SimulatorApp

  run! if app_file == $0
end
