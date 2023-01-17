require 'mechanize'
require 'logger'
require 'game'
require 'cbs_games'

# class CBSGames
#   def initialize(games_page)
#     @games = games_page.xpath("//div[contains(@class, 'single-score-card')]")
#   end

#   def each
#     return enum_for(:each) unless block_given?

#     classify_games.each do |game_element|
#       yield extract_data(game_element)
#     end
#   end

#   private

#   attr_reader :games

#   def classify_games
#     games.each do |game|
#       id = game.attributes["id"]
#       next unless id && id.value =~ /game-\d+/

#       if !game.xpath("div/div/div[contains(@class, 'pregame')]").empty?
#         groups[:pregame] << game
#       elsif !(postgame = game.xpath("div/div/div[contains(@class, 'postgame')]")).empty?
#         if postgame.text.downcase.start_with?("final")
#           groups[:postgame] << game
#         else
#           groups[:cancelled] << game
#         end
#       else
#         groups[:in_progress] << game
#       end
#     end

#     groups
#   end

#   def extract_data(game_element)
#     rows = game_element.xpath("div/div[contains(@class, 'in-progress-table')]/table/tbody/tr")
#     raise "Expected 2 rows, found: #{rows.size}" unless rows.size == 2

#     game_name = game_element.xpath("div/div[contains(@class, 'series-statement')]")[0].text.strip

#     visitor = extract_team_data(rows[0])
#     home = extract_team_data(rows[1])
#     status = parse_game_status(game_element, game_name)

#     { game_name: game_name, visitor: visitor, home: home, status: status }
#   end

#   def extract_team_data(element)
#     cells = element.xpath("td")
#     final_score = cells[-1].text.to_i
#     intermediate_scores = cells.drop(1).take(cells.size - 2).map { |cell| cell.text.to_i }
#     team_name = cells[0].xpath("a").last.text.strip

#     { team_name: team_name, score: final_score, intermediate_scores: intermediate_scores }    
#   end

#   def parse_game_status(game_element, game_name)
#     status = game_element.xpath("div/div/div[contains(@class, 'game-status')]")[0].text.strip
#     raise "No status found for game: #{game_name}" unless status

#     if status.downcase == "final"
#       { quarter: "final" }
#     elsif status.downcase == "halftime"
#       { quarter: "halftime" }
#     elsif status.downcase == "cancelled"
#       { quarter: "cancelled" }
#     elsif (match = /(\d)\w{2}\s+(\d{1,2}:\d{2})/.match(status))
#       { quarter: match[1], remaining: match[2] }
#     else
#       { quarter: status }
#     end
#   end
# end

class CBSScores
  def initialize(
        season,
        url_format: 'https://www.cbssports.com/college-football/scoreboard/FBS/%{year}/postseason/%{week}/'
      )
    @games = Game.games_for_season(season)
    @urls = (16..20).map { |week| url_format % { year: season.year, week: week } }
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def check_score(game)
    game_status = @game_statuses.find do |status| 
      Bowl.normalize_name(status.game_name, season: game.season) == game.name 
    end
    
    if game_status
      teams = game.teams.filter do |team| 
        [
          Team.normalize_name(game_status.visitor_name), 
          Team.normalize_name(game_status.home_name)
        ].include?(team.name)
      end
      if teams.size != 2
        game_status.status = "team_mismatch"
        game_status
      else
        game_status
      end
    else
      game_status.status = "missing"
      game_status
    end
  end

  def scrape
    @game_statuses = scrape_statuses
  end

  def scrape_statuses
    urls.reduce([]) do |memo, url|
      cbs_games = CBSGames.new(agent.get(url))
      memo + cbs_games.each.to_a
    end
  end

  private

  attr_reader :games, :logger, :agent, :urls

  def season
    games.first.season
  end

  # def safe_score(result, no_status: false)
  #   score(result, no_status: false)
  # rescue StandardError => ex
  #   logger.error "Error extracting score: #{ex.message}\n#{ex.backtrace.join("\n")}"
  #   nil
  # end

  # def score(result, no_status: false)
  #   game_record = games.find { |g| g.bowl.name == Bowl.normalize_name(result[:game_name].split(",").first, season: season) }
  #   raise "No game found for: #{result[:game_name]}" unless game_record

  #   if result[:status][:quarter] == "cancelled"
  #     {
  #       game: game_record,
  #       status: "cancelled"
  #     }
  #   else
  #     visitor = game_record.teams.find { |t| t.name == Team.normalize_name(result[:visitor][:team_name]) }
  #     raise "No team found for: #{result[:visitor][:team_name]}" unless visitor
  #     home = game_record.teams.find { |t| t.name == Team.normalize_name(result[:home][:team_name]) }
  #     raise "No team found for: #{result[:home][:team_name]}" unless home

  #     new_result = {
  #       game: game_record,
  #       visitor: result[:visitor].merge(team: visitor),
  #       home: result[:home].merge(team: home),
  #     }
  #     new_result[:status] = result[:status] unless no_status

  #     new_result
  #   end
  # end
end
