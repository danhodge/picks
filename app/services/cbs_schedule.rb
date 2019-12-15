require 'mechanize'
require 'logger'
require 'bowl'

class CBSSchedule
  STATE_ABBREVIATIONS = {
    'Ariz.' => 'AZ',
    'Calif.' => 'CA',
    'Fla.' => 'FL',
    'Texas' => 'TX',
    'Idaho' => 'ID',
    'Ala.' => 'AL',
    'Tenn.' => 'TN',
    'N.C.' => 'NC',
    'Md.' => 'MD',
    'La.' => 'LA',
    'Nev.' => 'NV',
    'N.M.' => 'NM'
  }.freeze

  STATES_BY_CITY = {
    'Atlanta' => 'GA',
    'New Orleans' => 'LA',
    'Dallas' => 'TX',
    'Phoenix' => 'AZ',
    'San Diego' => 'CA',
    'Houston' => 'TX',
    'New York' => 'NY',
    'Detroit' => 'MI',
    'Honolulu' => 'HI'
  }.freeze

  def self.normalize_location(location)
    city, state = location.split(',').map(&:strip)
    if state && state.include?('.') || %w(Texas Idaho).include?(state)
      state = STATE_ABBREVIATIONS[state]
    elsif !state
      state = STATES_BY_CITY[city]
    end

    [city, state]
  end

  def initialize(season, url: "https://www.cbssports.com/college-football/news/#{season.name}-bowl-schedule-college-football-games-dates-kickoff-times-tv-channels/")
    @season = season
    @url = url
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def scrape
    page = agent.get(url)
    tables = page.search("//table")
    tables.flat_map.with_index do |table, i|
      table.search("tr").drop(1).map do |row|
        date, game, time, matchup = row.search("td")

        game_time = to_time(date.text.strip, time.text.strip)
        game_name, raw_location = extract_text(game).take(2)

        if i == 0 && Bowl.championship?(game_name)
          [game_name, nil, nil, nil, nil, game_time, Game::GAME_TYPE_CHAMPIONSHIP]
        else
          city, state = self.class.normalize_location(raw_location)
          visitor, home = matchup.text.split("vs.").map { |value| parse_team(value.strip) }
          [game_name, city, state, visitor, home, game_time, (i == 0) ? Game::GAME_TYPE_SEMIFINAL : Game::GAME_TYPE_REGULAR]
        end
      end.compact
    end
  end

  def scrape_and_create
    Game.transaction do
      scrape.map do |game_name, city, state, visitor, home, game_time, game_type|
        bowl = Bowl.where(name: game_name).first_or_create! do |b|
          b.city = city
          b.state = state
        end

        if game_type != Game::GAME_TYPE_CHAMPIONSHIP
          visiting_team = Team.where(name: visitor[:name]).first_or_create!
          Record.where(season: season, team: visiting_team).first_or_create! do |v|
            v.wins = visitor[:wins]
            v.losses = visitor[:losses]
            v.ranking = visitor[:ranking]
          end

          home_team = Team.where(name: home[:name]).first_or_create!
          Record.where(season: season, team: home_team).first_or_create! do |v|
            v.wins = home[:wins]
            v.losses = home[:losses]
            v.ranking = home[:ranking]
          end
        end

        Game.where(season: season, bowl: bowl).first_or_create! do |g|
          g.visitor = visiting_team
          g.home = home_team
          g.game_time = game_time
          g.game_type = game_type
        end
      end
    end
  end

  private

  attr_reader :agent, :url, :season

  def to_time(date, time)
    time = "12:00 pm" if time.downcase.include?("noon")
    time = "8:00 pm" if time.include?("TBA")

    hm, meridian = time.split(" ").take(2)
    hm = "#{hm}:00" unless hm.include?(":")
    year = season.year
    year += 1 if date.start_with?('Jan')

    time_str = [date.gsub(/\./, ''), year, hm, meridian.gsub(/\./, ''), '-0500'].join(' ')

    Time.strptime(time_str, '%b %d %Y %l:%M %P %z')
  end

  def extract_text(node, result=[])
    node.children.each_with_object(result) do |child, r|
      if !child.children.empty?
        extract_text(child, r)
      elsif child.text?
        r << child.text.strip
      end
    end
  end

  def parse_team(team_str)
    tokens = team_str.split(' ')
    raw_record = tokens.pop
    raw_ranking = tokens.shift if tokens[0].start_with?('(')

    result = { name: tokens.join(' ') }
    result[:ranking] = raw_ranking[1..-2].to_i if raw_ranking
    result[:wins], result[:losses] = raw_record[1..-2].split('-').map(&:to_i)

    result
  end
end
