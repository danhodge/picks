require 'mechanize'
require 'logger'
require 'game'

class CBSScores
  def initialize(season, url: 'https://www.cbssports.com/college-football/scoreboard/FBS/2019/postseason/17/')
    @games = Game.games_for_season(season)
    @url = url
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def scrape
    page = agent.get(url)
    [extract_in_progress_scores(page), extract_postgame_scores(page)]
  end

  def extract_postgame_scores(games_page)
    games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
    groups = classify_games(games)
    groups[:postgame].map { |game| safe_extract_score(game, no_status: true) }.compact
  end

  def extract_in_progress_scores(games_page)
    games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
    groups = classify_games(games)
    groups[:in_progress].map { |game| safe_extract_score(game) }.compact
  end

  private

  attr_reader :games, :agent, :url

  def classify_games(games_page)
    groups = {
      in_progress: [],
      pregame: [],
      postgame: []
    }

    games_page.each do |game|
      id = game.attributes["id"]
      next unless id && id.value =~ /game-\d+/

      if !game.xpath("div/div/div[contains(@class, 'pregame')]").empty?
        groups[:pregame] << game
      elsif !game.xpath("div/div/div[contains(@class, 'postgame')]").empty?
        groups[:postgame] << game
      else
        groups[:in_progress] << game
      end
    end

    groups
  end

  def safe_extract_score(game, no_status: false)
    extract_score(game, no_status: false)
  rescue StandardError => ex
    logger.error "Error extracting score: #{ex.message}\n#{ex.backtrace.join("\n")}"
  end

  def extract_score(game, no_status: false)
    rows = game.xpath("div/div[contains(@class, 'in-progress-table')]/table/tbody/tr")
    raise "Expected 2 rows, found: #{rows.size}" unless rows.size == 2

    game_name = game.xpath("div/div[contains(@class, 'series-statement')]")[0].text.strip
    game_record = games.find { |g| g.bowl.name == Bowl.normalize_name(game_name) }
    raise "No game found for: #{game_name}" unless game_record

    visitor = extract_team(game_record, rows[0])
    home = extract_team(game_record, rows[1])
    status = parse_game_status(game)

    result = { game: game_record, visitor: visitor, home: home }
    result[:status] = status unless no_status

    result
  end

  def extract_team(game, row)
    cells = row.xpath("td")
    final_score = cells[-1].text.to_i
    intermediate_scores = cells.drop(1).take(cells.size - 2).map { |cell| cell.text.to_i }
    name = cells[0].xpath("a[contains(@class, 'team')]").first.text.strip
    team = game.teams.find { |t| t.name == Team.normalize_name(name) }
    raise "No team found for: #{name}" unless team

    { team: team, score: final_score, intermediate_scores: intermediate_scores }
  end

  def parse_game_status(game)
    status = game.xpath("div/div/div[contains(@class, 'game-status')]")[0].text.strip
    raise "No status found for game: #{game}" unless status

    if status.downcase == "final"
      { quarter: "final" }
    elsif status.downcase == "halftime"
      { quarter: "halftime" }
    elsif (match = /(\d)\w{2}\s+(\d{1,2}:\d{2})/.match(status))
      { quarter: match[1], remaining: match[2] }
    else
      { quarter: status }
    end
  end
end
