require 'sinatra/base'
require 'sinatra/activerecord'
require 'participants'

class Server < Sinatra::Base
  register Sinatra::ActiveRecordExtension

  set :root, File.dirname(__FILE__).tap { |r| puts "ROOT = #{r}" }
  # https://stackoverflow.com/questions/5055489/sinatra-static-assets-are-not-found-when-using-rackup
  set :public_folder, File.expand_path("public", File.dirname(__FILE__)).tap { |pf| puts "PF = #{pf}" }
  set :views, File.expand_path('views', File.dirname(__FILE__)).tap { |r| puts "root = #{root}, VIEWS = #{r}" }
  set :static, true
  set :static_cache_control, [:public, max_age: 1]

  use ::Participants

  run! if app_file == $0
end
