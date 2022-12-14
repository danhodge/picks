require 'models'

class SimulatorApp < Sinatra::Base
  set :views, File.expand_path('../views/simulator', File.dirname(__FILE__))

  get '/family_fun.html' do
    erb :"landing.html"
  end

  get '/add_participant.html' do
    erb :"add_participant.html"
  end
end
