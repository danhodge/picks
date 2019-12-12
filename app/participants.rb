require 'models'

class Participants < Sinatra::Base
  set :views, File.expand_path('../views', File.dirname(__FILE__))

  get '/add_participant' do
    content_type 'text/html'

    user = if (session = Session.find_by(token: params[:session])) && !session.expired?
             session.user
           elsif (user = User.find_by(token: params[:token]))
             session = User.transaction do
               user.token = nil
               user.save!
               Session.create!(user: user)
             end
             response.set_cookie(:session, value: session.token)  # TODO: domain? secure? expiration?

             user
           end

    if user
      games = Game.where(season: Season.current).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
        [game.game_time.to_date, game.bowl.name, game.visitor.name, game.home.name].join(" ")
      end

      erb :add_participant, layout: :basic, locals: { user: user, games: games }
    else
      redirect "/error.html"
    end
  end
end
