require 'mechanize'
require 'logger'
require 'agent_ext'
require 'bowl'

using SuppressLanguageCharset

class FamilyFunSchedule
  Result = Struct.new(:games, :participants) do
    def add_participant(participant)
      self.participants << participant
    end
  end

  def self.scrape(season, url: 'https://broadjumper.com/family_fun.html')
    agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = Logger.new(STDOUT)
    end

    new(season, agent.get(url)).scrape
  end

  def initialize(season, page)
    @season = season
    @page = page
  end

  def scrape
    create(extract_picks)
  end

  def create(results)
    Bowl.transaction do
      games = []
      results[:schedule].each do |result|
        bowl = Bowl.where(name: Bowl.normalize_name(result[:game], season: season)).first_or_create! do |b|
          city, state = result[:location].split(", ")
          b.city, b.state = b.normalize_location(city, state)
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

        game = Game.where(bowl: bowl, season: season, visitor: visiting_team, home: home_team).first_or_create! do |g|
          g.game_time = result[:time]
          g.game_type = Game::GAME_TYPE_REGULAR
        end
        games << game
      end

      results[:participants].each do |participant|
        pt = Participant.where(season: season, nickname: participant[:name]).first_or_create! do |p|
          p.tiebreaker = participant[:tie_breaker]
        end

        participant[:picks].zip(games).each do |pick, game|
          pk = Pick.where(participant: pt, game: game).first_or_initialize
          pk.team = game.teams.find { |t| t.name == Team.normalize_name(pick[:team]) }
          pk.points = pick[:points]
          pk.save!
        end
      end
    end
  end

  def extract_picks
    table = page.search('//table').first

    schedule = []
    result = { schedule: schedule, participants: [] }

    table.search('//tr').each_with_index do |row, i|
      case i
      when 0
        # 0 = games
        row.search('td').drop(1).each { |cell| schedule << { game: cell.text } }
      when 1
        # 1 = locations
        row.search('td').drop(1).each_with_index { |cell, j| schedule[j][:location] = cell.text }
      when 2
        # 2 = date/time
        row.search('td').drop(1).each_with_index do |cell, j|
          date_time = cell.children[0].children.map(&:text).values_at(0, 2).join(' ')
          game_year = date_time.start_with?('Dec') ? season.year : season.year + 1
          schedule[j][:time] = DateTime.strptime("#{game_year} #{date_time} -0500", '%Y %b. %d %I:%M %p %z').iso8601
        end
      # 3 = TV
      # 4 = Result
      when 5
        # 5 = teams
        row.search('td').drop(1).each_slice(2).each_with_index do |(visitor, home), j|
          schedule[j][:visitor] = visitor.text
          schedule[j][:home] = home.text
        end
      when 6
        # 6 = records
        row.search('td').drop(1).each_slice(2).take(schedule.size).each_with_index do |(visitor, home), j|
          schedule[j][:visitor_wins], schedule[j][:visitor_losses] = visitor.text.gsub(/\(/, '').gsub(/\)/, '').split('-').map(&:to_i)
          schedule[j][:home_wins], schedule[j][:home_losses] = home.text.gsub(/\(/, '').gsub(/\)/, '').split('-').map(&:to_i)
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

  attr_reader :page, :year_indicator, :season

  def handle_participant(result, cells)
    picks = cells.drop(1).take(result[:schedule].count * 2).each_slice(2).each_with_index.map do |(visitor, home), i|
      visitor_points = visitor.text
      home_points = home.text

      if visitor_points.length > 0
        { team: result[:schedule][i][:visitor], points: visitor_points.to_i }
      elsif home_points.length > 0
        { team: result[:schedule][i][:home], points: home_points.to_i }
      end
    end

    name = cells[0].text
    tie_breaker = cells.drop(3 + (result[:schedule].count * 2)).first.text
    if !tie_breaker || tie_breaker.empty?
      puts "Defaulting tie breaker to 0 for #{name}"
      tie_breaker = 0
    end

    if (picks.length == result[:schedule].length) && (picks.compact.length == picks.length)
      result[:participants] << { name: name, tie_breaker: tie_breaker, picks: picks }
    else
      puts "Ignoring participant: #{name} due to missing picks"
    end
  end
end
