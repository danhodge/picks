require 'models'

class Participants < Sinatra::Base
  set :views, File.expand_path('../views', File.dirname(__FILE__))

  get '/add_participant' do
    content_type 'text/html'

    user = if (session = Session.find_by(token: request.cookies["session"])) && !session.expired?
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
      participant = Participant.ensure!(user)
      picks_by_game_id = participant.picks.map { |pick| [pick.game_id, [pick.team_id, pick.points]] }.to_h

      games = Game.where(season: participant.season).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
        {
          date: game.game_time.to_date,
          id: game.id,
          name: game.bowl.name,
          visitor: {
            id: game.visitor.id,
            name: game.visitor.name
          },
          home: {
            id: game.home.id,
            name: game.home.name
          },
          chosen_team_id: picks_by_game_id[game.id][0],
          points: picks_by_game_id[game.id][1]
        }
      end

      erb :add_participant, layout: :basic, locals: { user: user, games: games }
    else
      redirect "/error.html"
    end
  end

  post '/picks' do
    Pick.transaction do
      session = Session.find_by(token: request.cookies["session"])
      user = session.user unless session.nil? || session.expired?

      if user
        season = Season.current
        picks = Pick.where(season: season, participant: Participant.find_by(user: user, season: season))

        picks.each do |pick|
          pick.points = params[:points][pick.game_id.to_s]
          pick.team_id = params[:choice][pick.game_id.to_s]
        end

        picks.each(&:save!)

        redirect '/add_participant'
      else
        redirect "/error.html"
      end
    end
  end
end
