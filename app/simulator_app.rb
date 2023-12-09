require 'models'

class SimulatorApp < Sinatra::Base
  set :views, File.expand_path('../views/simulator', File.dirname(__FILE__))

  get '/family_fun.html' do
    season = Season.current
    year = "#{season.year.to_s[-2..-1]}/#{(season.year + 1).to_s[-2..-1]}"
    erb(
      :"landing.html", 
      locals: { 
        games: Season.current.games.order(:game_time), 
        year: year 
      }
    )
  end

  get '/add_participant.html' do
    erb :"add_participant.html"
  end

  post '/add_participant.html' do
    erb(
      :"picks.html", 
      locals: { 
        games: Season.current.games.order(:game_time) 
      }
    )
  end

end
