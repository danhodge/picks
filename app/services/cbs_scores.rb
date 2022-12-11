require 'mechanize'
require 'logger'
require 'game'

class CBSGames
  def initialize(games_page)
    @games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
  end

  def each_in_progress
    return enum_for(:each_in_progress) unless block_given?

    classify_games[:in_progress].each do |game_element|
      yield extract_data(game_element)
    end
  end

  def each_completed
    return enum_for(:each_completed) unless block_given?

    classify_games[:postgame].each do |game_element|
      yield extract_data(game_element)
    end
  end

  private

  attr_reader :games

  def classify_games
    groups = {
      in_progress: [],
      pregame: [],
      postgame: [],
      cancelled: []
    }

    games.each do |game|
      id = game.attributes["id"]
      next unless id && id.value =~ /game-\d+/

      if !game.xpath("div/div/div[contains(@class, 'pregame')]").empty?
        groups[:pregame] << game
      elsif !(postgame = game.xpath("div/div/div[contains(@class, 'postgame')]")).empty?
        if postgame.text.downcase.start_with?("final")
          groups[:postgame] << game
        else
          groups[:cancelled] << game
        end
      else
        groups[:in_progress] << game
      end
    end

    groups
  end

  def extract_data(game_element)
    rows = game_element.xpath("div/div[contains(@class, 'in-progress-table')]/table/tbody/tr")
    raise "Expected 2 rows, found: #{rows.size}" unless rows.size == 2

    game_name = game_element.xpath("div/div[contains(@class, 'series-statement')]")[0].text.strip

    visitor = extract_team_data(rows[0])
    home = extract_team_data(rows[1])
    status = parse_game_status(game_element, game_name)

    { game_name: game_name, visitor: visitor, home: home, status: status }
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

class CBSScores
  def initialize(
        season,
        urls: [
          'https://www.cbssports.com/college-football/scoreboard/FBS/2022/postseason/16/',
          'https://www.cbssports.com/college-football/scoreboard/FBS/2022/postseason/17/',
          'https://www.cbssports.com/college-football/scoreboard/FBS/2022/postseason/18/'
        ]
      )
    @games = Game.games_for_season(season)
    @urls = urls
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def scrape
    urls.reduce([[], []]) do |(in_progress, completed), url|
      cbs_games = CBSGames.new(agent.get(url))
      [
        in_progress + cbs_games.each_in_progress.map(&method(:safe_score)).compact, 
        completed + cbs_games.each_completed.map(&method(:safe_score)).compact
      ]
    end
  end

  private

  attr_reader :games, :logger, :agent, :urls

  def safe_score(result, no_status: false)
    score(result, no_status: false)
  rescue StandardError => ex
    logger.error "Error extracting score: #{ex.message}\n#{ex.backtrace.join("\n")}"
    nil
  end

  def score(result, no_status: false)
    game_record = games.find { |g| g.bowl.name == Bowl.normalize_name(result[:game_name].split(",").first) }
    raise "No game found for: #{result[:game_name]}" unless game_record

    visitor = game_record.teams.find { |t| t.name == Team.normalize_name(result[:visitor][:team_name]) }
    raise "No team found for: #{result[:visitor][:team_name]}" unless visitor
    home = game_record.teams.find { |t| t.name == Team.normalize_name(result[:home][:team_name]) }
    raise "No team found for: #{result[:home][:team_name]}" unless home

    new_result = {
      game: game_record,
      visitor: result[:visitor].merge(team: visitor),
      home: result[:home].merge(team: home),
    }
    new_result[:status] = result[:status] unless no_status

    new_result
  end
end
