require 'sinatra/base'
require 'sinatra/activerecord'
require 'admin'
require 'participants'

class Server < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  set :root, File.dirname(__FILE__)
  set :public_folder, File.expand_path("public", File.dirname(__FILE__))
  set :views, File.expand_path('views', File.dirname(__FILE__))
  set :static, true
  set :static_cache_control, [:public, max_age: 1]

  use ::Participants
  use ::Admin

  run! if app_file == $0
end
