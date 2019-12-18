require 'logger'
require 'mechanize'

class FoxLines
  def initialize(season, url: 'http://www.foxsports.com/college-football/odds?group=0&type=2')
    @season = season
    @url = url
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
  end

  def scrape_and_create
    update_lines(extract_games(agent.get(url)))
  end

  def extract_games(page)
    container = page.search("//section[@class='wisbb_body']").first
    children = container.search("//div[@class='wisbb_gameWrapper']")

    children.map do |child|
      visitor, home = child.search('span[@class="wisbb_teamCity"]').map(&:text)

      raw_date, raw_time, game_name = child.search('span[@class="wisbb_oddsGameDate"]').first.text.split(' - ').map(&:strip)
      modified_time = raw_time.gsub(/a/, 'am').gsub(/p/, 'pm').gsub('ET', '-05:00')

      time = DateTime.strptime("#{raw_date} #{modified_time}", '%a, %b %d, %Y %l:%M%P %z').iso8601

      odds = child.search('table[@class="wisbb_standardTable wisbb_oddsTable wisbb_altRowColors"]').first
      point_spreads = odds.search('tr').drop(1).map do |row|
        cell = row.search("td[@class='wisbb_runLinePtsCol']").first
        [cell.children.first.text.to_f, cell.children.last.text.to_f]
      end

      [
        game_name,
        time,
        visitor,
        (point_spreads.map(&:first).reduce(:+) / point_spreads.length),
        home,
        (point_spreads.map(&:last).reduce(:+) / point_spreads.length)
      ]
    end
  end

  def update_lines(results)
    Game.transaction do
      results.each do |game_name, time, visitor, visitor_point_spread, home, home_point_spread|
        bowl = Bowl.find_by!(name: Bowl.normalize_name(game_name))

        visitor = Team.find_by!(name: Team.normalize_name(visitor))
        home = Team.find_by!(name: Team.normalize_name(home))

        game = Game.find_by!(season: season, bowl: bowl)
        raise "Game time mismatch for #{game} - expected #{time}" unless (game.game_time - Time.parse(time)).abs <= 3600

        if game.home == home && game.visitor == visitor
          game.point_spread = visitor_point_spread
        elsif game.home == visitor && game.visitor == home
          game.point_spread = home_point_spread
        else
          raise "Team mismatch for #{game} - expected #{visitor} vs. #{home}"
        end
        game.save!

        # TODO: update record
      end
    end
  end

  private

  attr_reader :logger, :agent, :url, :season
end
