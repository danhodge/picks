require 'logger'
require 'mechanize'
require 'pry'

class CBSLines
  def self.scrape_and_create(season, url: "https://www.cbssports.com/college-football/news/college-football-odds-lines-predictions-for-the-2022-23-bowl-season-proven-model-picks-washington-usc/")
    agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = Logger.new(STDOUT)
    end

    new(season, page: agent.get(url)).scrape_and_create
  end

  GAME_TEAMS_LINE = /(?<game>.+): (?<visitor>.+) vs\. (?<home>.+) \((?<line>[\+-][\d\.]+)(?:, [\d\.]+)?\)/

  def initialize(season, file: nil, page: nil)
    raise ArgumentError, "file or page must be specified" unless file || page

    @season = season
    @page = page || Mechanize::Page.new(nil, nil, File.read(file), 200, Mechanize.new)
  end

  def scrape_and_create
    update_lines(extract_games(page))
  end

  def extract_games(page)
    container = page.search("//div[@id='Article-body']").first
    children = container.search("p")

    cur_date = nil
    results = []
    children.each do |child|
      l2 = child.search("strong")
      if l2.size == 1 && (date = parse_date(l2.first.text))
        cur_date = date
      elsif cur_date
        if match = GAME_TEAMS_LINE.match(child.text)
          name_tokens = match[:game].split(" ")
          name_tokens.shift if name_tokens[0] == Season.current.year.to_s || (Season.current.year + 1).to_s

          results << [
            name_tokens.join(" "),
            cur_date,
            strip_ranking(match[:visitor]),
            strip_ranking(match[:home]),
            Float(match[:line])
          ]
        end
      end
    end

    results
  end

  def update_lines(results)
    Game.transaction do
      results.each do |game_name, date, visitor_name, home_name, point_spread|
        visitor = Team.find_by!(name: Team.normalize_name(visitor_name))
        home = Team.find_by!(name: Team.normalize_name(home_name))

        bowl = find_bowl!(game_name, visitor, home)
        game = Game.find_by!(season: season, bowl: bowl)
        # not useful without time information
        #raise "Game time mismatch for #{game} - expected #{date}" unless game.game_time.to_date == date

        if game.home == home && game.visitor == visitor
          game.point_spread = point_spread * -1
        elsif game.home == visitor && game.visitor == home
          game.point_spread = point_spread
        else
          raise "Team mismatch for #{game.bowl.name} - expected #{visitor.name} vs. #{home.name}"
        end
        game.save!
      end
    end
  end

  private

  def parse_date(raw_date)
    time = Time.strptime(raw_date, "%A, %b. %d")
    if time < Time.now
      time = time.next_year
    end

    time.to_date
  rescue ArgumentError
    nil
  end

  def strip_ranking(team_name)
    team_tokens = team_name.split(" ")
    if team_tokens[0] == "No." && team_tokens[1] =~ /^\d+$/
      team_tokens[2..].join(" ")
    else
      team_name
    end
  end

  def find_bowl!(game_name, visitor, home)
    if Bowl.semifinal?(game_name)
      games = Game.where(bowl: Bowl.semifinal_bowls(season), season: season)
      game = games.find do |g|
        (g.home == home && g.visitor == visitor) ||
          (g.home == visitor && g.visitor == home)
      end
      raise "No Bowl found for: #{game_name} - #{visitor.name} vs. #{home.name}" unless game

      game.bowl
    else
      Bowl.find_by!(name: Bowl.normalize_name(game_name))
    end
  end

  attr_reader :page, :season
end
