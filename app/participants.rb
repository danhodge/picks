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

    def logout
      session = current_session
      if session
        session.destroy
        response.set_cookie(:session, value: "", expires: Time.now - 60)
      end
    end

    def render_picks(participant: current_participant, message: "", errors: [])
      picks_by_game_id = participant.picks.map { |pick| [pick.game_id, [pick.team_id, pick.points]] }.to_h

      games = Game.where(season: current_season).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
        pick = picks_by_game_id[game.id]
        est_time = game.game_time.getlocal('-05:00')

        game_data = {
          date: est_time.strftime("%b %d"),
          time: est_time.strftime("%l:%M %P"),
          id: game.id,
          name: game.bowl.name,
          type: game.game_type,
          chosen_team_id: pick && pick[0],
          points: pick && pick[1]
        }

        game_data[:visitor] = {
          id: game.visitor.id,
          name: game.visitor.name
        } if game.visitor

        game_data[:home] = {
          id: game.home.id,
          name: game.home.name
        } if game.home

        game_data
      end

      erb(
        :picks,
        layout: :basic,
        locals: {
          participant: participant,
          games: games,
          message: message,
          errors: errors,
          season: { name: current_season.name, total_points: current_season.total_points }
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

    def invalid_nickname?(nickname)
      (nickname.strip.length > 32 || !(nickname =~ /\A[A-Za-z0-9 _\.]+\z/))
    end
  end

  get '/' do
    redirect "/login.html"
  end

  get '/add_participant' do
    content_type 'text/html'

    logout
    user = current_user

    if !user
      redirect '/error.html'
    elsif current_participant
      redirect '/picks'
    else
      erb :add_participant, layout: :basic, locals: { nickname: "", token: user.token, errors: [] }
    end
  end

  post '/add_participant' do
    user = current_user

    if !user
      redirect '/error.html'
    elsif current_participant
      redirect '/picks'
    else
      errors = []
      errors << "nickname required" if params[:nickname].strip.empty?
      if Participant.where(season: current_season, nickname: params[:nickname].strip).exists?
        errors << "nickname is already reservered"
      end
      errors << "invalid nickname" if invalid_nickname?(params[:nickname])
      errors << "password required" if params[:password].strip.empty?
      errors << "passwords do not match" if params[:password] != params[:confirm_password]
      errors << "password must be at least 8 characters" if params[:password] && params[:password].strip.length < 8

      if !errors.empty?
        erb :add_participant, layout: :basic, locals: { nickname: params[:nickname].strip, token: user.token, errors: errors }
      else
        session, participant = Participant.transaction do
          user.token = nil
          user.password = password_digest(params[:password])
          user.save!

          [Session.create!(user: user), Participant.ensure!(user: user, nickname: params[:nickname].strip, season: current_season)]
        end
        response.set_cookie(:session, value: session.token)  # TODO: domain? secure? expiration?

        render_picks(participant: participant)
      end
    end
  end

  get '/login' do
    user = logged_in_user
    if user
      redirect '/picks'
    else
      erb :login, layout: :basic, locals: { errors: [] }
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
        erb :login, layout: :basic, locals: { errors: ["invalid username"] }
      end
    end
  end

  get '/logout' do
    logout

    redirect "/login"
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
    begin
      if Time.now >= current_season.cutoff_time
        render_picks(errors: ["picks are no longer being accepted"])
        return
      end

      Pick.transaction do
        if (participant = current_participant)
          picks_by_game = Pick.where(season: current_season, participant: participant).map { |pick| [pick.game_id, pick] }.to_h

          params[:choice].each do |game_id, team_id|
            pick = picks_by_game[game_id.to_i] || Pick.new(season_id: participant.season.id, participant_id: participant.id, game_id: game_id.to_i)
            pick.team_id = team_id.to_i
            pick.points = params[:points][game_id.to_s]
            pick.save!
          end
          participant.update_attributes!(tiebreaker: Integer(params[:tiebreaker]))
          participant.reload.validate_picks!

          render_picks(message: "picks updated successfully")
        else
          redirect "/error.html"
        end
      end
    rescue => ex
      render_picks(errors: ["error updating picks - #{ex.message}"])
    end
  end
end
