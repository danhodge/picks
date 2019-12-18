require 'mechanize'
require 'logger'
require 'bowl'

class FamilyFunSchedule
  Result = Struct.new(:games, :participants) do
    def add_participant(participant)
      self.participants << participant
    end
  end


  def initialize(season, url: 'http://broadjumper.com/family_fun.html')
    @base_url = url
    @season = season
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def scrape
    create(extract_picks(agent.get("#{base_url}")))
  end

  def create(results)
    Bowl.transaction do
      results.each do |result|
        bowl = Bowl.where(name: Bowl.normalize_name(result[:game])).first_or_create! do |b|
          b.city, b.state = result[:location].split(", ")
        end

        visiting_team = Team.where(name: Team.normalize_name(result[:visitor])).first_or_create!
        Record.where(season: season, team: visiting_team).first_or_create! do |v|
          v.wins = result[:visitor_wins]
          v.losses = result[:visitor_losses]
        end

        home_team = Team.where(name: Team.normalize_name(result[:home])).first_or_create!
        Record.where(season: season, team: home_team).first_or_create! do |v|
          v.wins = result[:home_wins]
          v.losses = result[:home_losses]
        end

        Game.where(bowl: bowl, season: season, visitor: visiting_team, home: home_team).first_or_create! do |g|
          g.game_time = result[:time]
          g.game_type = Game::GAME_TYPE_REGULAR
        end
      end
    end
  end

  def extract_picks(page)
    table = page.search('//table').first

    result = []

    table.search('//tr').each_with_index do |row, i|
      case i
      when 0
        # 0 = games
        row.search('td').drop(1).each { |cell| result << { game: cell.text } }
      when 1
        # 1 = locations
        row.search('td').drop(1).each_with_index { |cell, j| result[j][:location] = cell.text }
      when 2
        # 2 = date/time
        row.search('td').drop(1).each_with_index do |cell, j|
          date_time = cell.children[0].children.map(&:text).values_at(0, 2).join(' ')
          game_year = date_time.start_with?('Dec') ? season.year : season.year + 1
          result[j][:time] = DateTime.strptime("#{game_year} #{date_time} -0500", '%Y %b. %d %I:%M %p %z').iso8601
        end
      # 3 = TV
      # 4 = Result
      when 5
        # 5 = teams
        row.search('td').drop(1).each_slice(2).each_with_index do |(visitor, home), j|
          result[j][:visitor] = visitor.text
          result[j][:home] = home.text
        end
      when 6
        # 6 = records
        row.search('td').drop(1).each_slice(2).take(result.size).each_with_index do |(visitor, home), j|
          result[j][:visitor_wins], result[j][:visitor_losses] = visitor.text.gsub(/\(/, '').gsub(/\)/, '').split('-').map(&:to_i)
          result[j][:home_wins], result[j][:home_losses] = home.text.gsub(/\(/, '').gsub(/\)/, '').split('-').map(&:to_i)
        end
      when -> (n) { n >= 8 }
        # rows 8 - end are participants
        cells = row.search('td')
        handle_participant(result, cells)
      end
    end

    result
  end

  private

  attr_reader :base_url, :year_indicator, :logger, :agent, :season

  def handle_participant(result, cells)
    picks = cells.drop(1).take(result.games.count * 2).each_slice(2).each_with_index.map do |(visitor, home), i|
      visitor_points = visitor.text
      home_points = home.text

      if visitor_points.length > 0
        Pick.new(result.games[i], result.games[i].visitor, visitor_points.to_i)
      elsif home_points.length > 0
        Pick.new(result.games[i], result.games[i].home, home_points.to_i)
      end
    end

    name = cells[0].text
    if picks.length == result.games.length && picks.compact.length == picks.length
      tie_breaker = cells.drop(3 + (result.games.count * 2)).first.text
      result.add_participant(Participant.new(name, tie_breaker, picks))
    else
      logger.error "Ignoring participant: #{name} due to missing picks"
    end
  end
end
