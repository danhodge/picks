require 'user'
require 'session'

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
      erb :add_participant, layout: :basic, locals: { user: user }
    else
      redirect "/error.html"
    end
  end
end
