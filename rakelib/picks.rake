require 'csv'
require 'season'
require 'bowl'
require 'team'
require 'game'
require 'enter_picks'
require 'generate_picks'

namespace :picks do
  task generate_csv: "db:load_config" do
    season = Season.current
    CSV.open("picks_#{season.year}.csv", 'w') do |csv|
      csv << %w(Date Game Location Visitor Home Favorite Spread Choice Adjustment)
      Game.games_for_season(season).map do |game|
        csv << [
          game.game_time.getlocal('-05:00').to_date,
          game.bowl.name,
          [game.bowl.city, game.bowl.state].join(", "),
          game.visitor.name,
          game.home.name,
          game.point_spread < 0 ? game.visitor.name : game.home.name,
          game.point_spread.abs.round(1),
          "",
          ""
        ]
      end
    end
  end

  task :generate_and_submit, [:csv_path, :tie_breaker, :username, :password] => "db:load_config" do |_task, args|
    raise ArgumentError, "csv_path must be provided" unless args[:csv_path]
    raise ArgumentError, "tie breaker must be provided" unless args[:tie_breaker]
    raise ArgumentError, "username must be provided" unless args[:username]
    raise ArgumentError, "password must be provided" unless args[:password]

    picks = GeneratePicks.new(Season.current, File.read(args[:csv_path])).compute
    enter = EnterPicks.new(username: args[:username], password: args[:password])
    enter.submit_picks(picks, Integer(args[:tie_breaker]))
  end
end
