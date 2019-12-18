require 'csv'
require 'season'
require 'bowl'
require 'team'
require 'game'

namespace :picks do
  task generate_csv: "db:load_config" do
    season = Season.current
    CSV.open("picks_#{season.year}.csv", 'w') do |csv|
      csv << %w(Date Game Location Visitor Home Favorite Spread Choice Adjustment)
      Game.where(season: season).includes(:bowl, :visitor, :home).order(:game_time, :id).map do |game|
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
end
