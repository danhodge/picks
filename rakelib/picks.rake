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
          game.favored_team.name,
          game.abs_point_spread,
          "",
          ""
        ]
      end
    end
  end

  task :generate_choices, [:randomness] => "db:load_config" do |_task, args|
    # 0 = low randomness, 100 = max randomness
    randomness_arg = (args[:randomness] || 0).to_i
    raise ArgumentError, "randomness must be in range [0, 100]" unless (0..100).include?(randomness_arg)

    std_dev_cutoff = (100 - randomness_arg) / 50.0
    random = RandomGaussian.create(1)

    season = Season.current
    CSV.open("picks_#{season.year}.csv", 'w') do |csv|
      Game.games_for_season(season).map do |game|
        adj = random.next * 1.5  # make adjustments more likely than upsets
        adjustment =
          if adj > std_dev_cutoff
            [(adj - std_dev_cutoff) * 3, 7].min
          elsif adj < -std_dev_cutoff
            [(adj + std_dev_cutoff) * 3, -7].max
          else
            0
          end

        # choose the favorite unless random is more thand std_dev_cutoff from the mean
        choice =
          if random.next.abs < std_dev_cutoff
            game.favored_team.name
          elsif game.home.name != game.favored_team.name
            game.home.name
          else
            game.visitor.name
          end

        csv << [
          game.game_time.getlocal('-05:00').to_date,
          game.bowl.name,
          [game.bowl.city, game.bowl.state].join(", "),
          game.visitor.name,
          game.home.name,
          game.favored_team.name,
          game.abs_point_spread,
          choice,
          adjustment.round(1)
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
