require 'mechanize'
require 'logger'
require 'game'

class CBSGames
  def initialize(games_page)
    @games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
  end

  def each
    return enum_for(:each) unless block_given?

    @games.each do |game_element|
      yield extract_data(game_element)
    end
  end

  private

  attr_reader :games

  def extract_data(game_element)
    rows = game_element.xpath("div/div[contains(@class, 'in-progress-table')]/table/tbody/tr")
    raise "Expected 2 rows, found: #{rows.size}" unless rows.size == 2

    game_name = game_element.xpath("div/div[contains(@class, 'series-statement')]")[0].text.strip

    visitor = extract_team_data(rows[0])
    home = extract_team_data(rows[1])
    status = parse_game_status(game_element, game_name)

    game_status = GameStatus.new(
      game_name.split(",").first,
      TeamStatus.new(visitor[:team_name], visitor[:score], visitor[:intermediate_scores]),
      TeamStatus.new(home[:team_name], home[:score], home[:intermediate_scores])
    )
    if %w(final cancelled).include?(status[:quarter])
      game_status.status = status[:quarter]
    elsif status[:quarter] == "halftime"
      game_status.quarter = 3
      game_status.remaining = "15:00"
    else
      game_status.quarter = status[:quarter]
      game_status.remaining = status[:remaining]
    end

    game_status
  end

  def extract_team_data(element)
    cells = element.xpath("td")
    final_score = cells[-1].text.to_i
    intermediate_scores = cells.drop(1).take(cells.size - 2).map { |cell| cell.text.to_i }
    team_name = cells[0].xpath("a").last.text.strip

    { team_name: team_name, score: final_score, intermediate_scores: intermediate_scores }    
  end

  def parse_game_status(game_element, game_name)
    status = game_element.xpath("div/div/div[contains(@class, 'game-status')]")[0].text.strip
    raise "No status found for game: #{game_name}" unless status

    if status.downcase == "final" || status.downcase =~ %r{final/(?<num_ots>\d)*ot}
      { quarter: "final" }
    elsif status.downcase == "halftime"
      { quarter: "halftime" }
    elsif status.downcase == "cancelled"
      { quarter: "cancelled" }
    elsif (match = /(\d)\w{2}\s+(\d{1,2}:\d{2})/.match(status))
      { quarter: match[1], remaining: match[2] }
    else
      { quarter: status }
    end
  end
end