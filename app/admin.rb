require 'models'

class Admin < Sinatra::Base
  set :views, File.expand_path('../views', File.dirname(__FILE__))

  helpers do
    def current_user
      logged_in_user
    end

    def logged_in_user
      session = current_session
      session && session.user
    end

    def current_session
      session = Session.find_by(token: request.cookies["session"])
      session unless session && session.expired?
    end

    def current_season
      Season.current
    end
  end

  get '/final_scores' do
    user = current_user
    if !user || !user.admin?
      redirect '/error.html'
    else
      erb :final_scores, layout: :basic, locals: { games: Game.games_for_season(current_season) }
    end
  end

  post '/final_scores' do
    user = current_user
    if !user || !user.admin?
      redirect '/error.html'
    else
      FinalScore.transaction do
        params[:score].each do |key, points|
          next if points.strip.empty?

          game_id, team_id = key.split('_')
          final = FinalScore.where(game_id: game_id, team_id: team_id).first_or_initialize
          final.points = points.to_i
          final.save!
        end
      end

      erb :final_scores, layout: :basic, locals: { games: Game.games_for_season(current_season) }
    end
  end
end
