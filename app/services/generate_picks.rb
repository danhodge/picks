require 'csv'
require 'set'
require 'stringio'
require 'random_gaussian'
require 'game'

class GeneratePicks
  Choice = Struct.new(:date, :game, :team, :confidence) do
    def self.from_row(row)
      confidence = if row["Choice"] == row["Favorite"]
                     row["Spread"].to_f + row["Adjustment"].to_f
                   elsif row["Spread"] == 'UNKNOWN'
                     row["Adjustment"].to_f
                   else
                     -(row["Spread"].to_f) + row["Adjustment"].to_f
                   end

      new(row["Date"], row["Game"], row["Choice"], confidence)
    end
  end

  def initialize(season, picks_csv)
    @choices = CSV.new(StringIO.new(picks_csv), headers: true).map { |row| Choice.from_row(row) }
    @rand = RandomGaussian.create(size.to_f / 8)
    @season = season
  end

  def size
    choices.size
  end

  def compute
    solutions = 5000.times.map do
      result = create_solution
      diff = result.reduce(0) do |memo, (choice, score)|
        memo + (map_to_score(choice.confidence) - score).abs
      end

      [diff, result]
    end

    best = solutions.sort_by(&:first).first

    games_by_name = Game.games_for_season(season).map { |game| [game.bowl.name, game] }.to_h
    best[1].map do |choice, confidence|
      game = games_by_name.fetch(choice.game)
      team = [game.visitor, game.home].find { |t| t.name == choice.team }

      [game, team, confidence]
    end
  end

  private

  attr_reader :choices, :rand

  def create_solution
    available = Set.new(1.upto(size))
    choices.shuffle.map do |choice|
      score = scale(rand.next, choice.confidence)
      [choice, take_closest(score, available)]
    end
  end

  def take_closest(score, available, distance: 1)
    delete_if_present(available, score) ||
      delete_if_present(available, (score - distance)) ||
      delete_if_present(available, (score + distance)) ||
      take_closest(score, available, distance: distance + 1)
  end

  def delete_if_present(set, item)
    if set.delete?(item)
      item
    else
      nil
    end
  end

  def scale(value, confidence)
    scaled = (value + map_to_score(confidence)).round
    [[scaled, size].min, 1].max
  end

  def map_to_score(confidence)
    mapping_function.call(confidence)
  end

  def min
    choices.map(&:confidence).min
  end

  def max
    choices.map(&:confidence).max
  end

  def mapping_function
    @mapper ||= begin
                  m = (size.to_f - 1) / (max.to_f - min)
                  b = 1 - m * min

                  proc { |x| (m * x + b).round }
                end
  end

  attr_reader :choices, :season
end
