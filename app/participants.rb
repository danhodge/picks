require 'models'

class Participants < Sinatra::Base
  set :views, File.expand_path('../views', File.dirname(__FILE__))

  get '/add_participant' do
    content_type 'text/html'

    user = if (session = Session.find_by(token: request.cookies["session"])) && !session.expired?
             session.user
           elsif params[:token] && (user = User.find_by(token: params[:token]))
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
      season = participant.season
      picks_by_game_id = participant.picks.map { |pick| [pick.game_id, [pick.team_id, pick.points]] }.to_h

      games = Game.where(season: season).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
        pick = picks_by_game_id[game.id]

        {
          date: game.game_time.strftime("%b %d"),
          time: game.game_time.strftime("%l:%M %P"),
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
          chosen_team_id: pick && pick[0],
          points: pick && pick[1]
        }
      end

      erb :add_participant, layout: :basic, locals: { user: user, games: games, season: { name: season.name, total_points: season.total_points} }
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
        participant = Participant.find_by(user: user, season: season)
        picks_by_game = Pick.where(season: season, participant: participant).map { |pick| [pick.game_id, pick] }.to_h

        params[:choice].each do |game_id, team_id|
          pick = picks_by_game[game_id.to_i] || Pick.new(season_id: season.id, participant_id: participant.id, game_id: game_id.to_i)
          pick.team_id = team_id.to_i
          pick.points = params[:points][game_id.to_s]
          pick.save!
        end
        participant.reload.validate_picks!

        redirect '/add_participant'
      else
        redirect "/error.html"
      end
    end
  end
end
