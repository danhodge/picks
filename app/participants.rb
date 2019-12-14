require 'models'

class Participants < Sinatra::Base
  set :views, File.expand_path('../views', File.dirname(__FILE__))

  helpers do
    def current_user
      logged_in_user || token_user
    end

    def current_participant
      current_user && current_user.participants.find_by(season: current_season)
    end

    def current_season
      Season.current
    end

    def current_session
      session = Session.find_by(token: request.cookies["session"])
      session unless session && session.expired?
    end

    def render_picks(participant: current_participant)
      picks_by_game_id = participant.picks.map { |pick| [pick.game_id, [pick.team_id, pick.points]] }.to_h

      games = Game.where(season: current_season).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
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

      erb(
        :picks,
        layout: :basic,
        locals: {
          participant: participant,
          games: games,
          season: { name: current_season.name, total_points: current_season.total_points}
        }
      )
    end

    def logged_in_user
      session = current_session
      session && session.user
    end

    def token_user
      params[:token] && User.find_by(token: params[:token])
    end

    def password_digest(password)
      # TODO: salt
      Digest::SHA2.new(512).hexdigest(password)
    end
  end

  get '/' do
    redirect "/login.html"
  end

  get '/add_participant' do
    content_type 'text/html'

    user = current_user

    if !user
      redirect '/error.html'
    elsif current_participant
      redirect '/picks'
    else
      erb :add_participant, layout: :basic, locals: { nickname: "", token: user.token }
    end
  end

  post '/add_participant' do
    user = current_user

    if !user
      redirect '/error.html'
    elsif current_participant
      redirect '/picks'
    else
      session, participant = Participant.transaction do
        user.token = nil
        user.password = password_digest(params[:password])
        user.save!

        [Session.create!(user: user), Participant.ensure!(user: user, nickname: params[:nickname], season: current_season)]
      end
      response.set_cookie(:session, value: session.token)  # TODO: domain? secure? expiration?

      render_picks(participant: participant)
    end
  end

  post '/sessions' do
    user = logged_in_user
    if user
      redirect '/picks'
    else
      participant = Participant
                      .where(nickname: params[:nickname], season: current_season)
                      .joins(:user)
                      .where("users.password" => password_digest(params[:password]))
                      .first

      if participant
        session = Session.create!(user: participant.user)
        response.set_cookie(:session, value: session.token)  # TODO: domain? secure? expiration?

        redirect '/picks'
      else
        redirect '/login.html'
      end
    end
  end

  get '/logout' do
    session = current_session
    if session
      session.destroy
      response.set_cookie(:session, value: "", expires: Time.now - 60)
    end

    redirect "/login.html"
  end

  get '/picks' do
    content_type 'text/html'

    if current_participant
      render_picks
    else
      redirect "/error.html"
    end
  end

  post '/picks' do
    Pick.transaction do
      if (participant = current_participant)
        picks_by_game = Pick.where(season: current_season, participant: participant).map { |pick| [pick.game_id, pick] }.to_h

        params[:choice].each do |game_id, team_id|
          pick = picks_by_game[game_id.to_i] || Pick.new(season_id: participant.season.id, participant_id: participant.id, game_id: game_id.to_i)
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
