require 'logger'
require 'mechanize'
require 'season'
require 'game'

class EnterPicks
  def initialize(username:, password:, url: 'http://broadjumper.com/add_participant.html', season: Season.current)
    @url = url
    @logger = Logger.new(STDOUT)
    @agent = Mechanize.new do |mechanize|
      mechanize.user_agent = 'Mac Safari'
      mechanize.log = @logger
    end
    @enter_picks_page = login(username, password)
    @season = season
  end

  def submit_picks(choices, tie_breaker)
    games = parse_table
    form = enter_picks_page.forms.first

    games.each_with_index do |game, i|
      choice = choices.find { |g, _t, _c| g == game[:game] }

      buttons = form.radiobuttons.select { |btn| btn.name == "win[#{i}]" }
      visitor_button = buttons.find { |btn| btn.value == "1" }
      home_button = buttons.find { |btn| btn.value == "2" }

      if choice[1] == game[:visitor]
        visitor_button.check
        home_button.uncheck
      elsif choice[1] == game[:home]
        visitor_button.uncheck
        home_button.check
      else
        raise "Invalid team chosen for game: #{choice[1].name}, #{choice[0].bowl.name}"
      end
      form["conf[#{i}]"] = choice[2]
    end
    form.tie = tie_breaker

    result = form.submit
    File.open("#{self.class}-#{Time.now.iso8601}-picks_saved.html", 'w') { |file| file << result.content }
    errors = result.xpath("//span[text()='CHANGES NOT SAVED!']")

    raise RuntimeError(errors.map(&:text).join) unless errors.empty?
  end

  private

  attr_reader :url, :agent, :enter_picks_page, :season

  def login(username, password)
    page = agent.get(url)
    File.open("#{self.class}-#{Time.now.iso8601}-login_page.html", 'w') { |file| file << page.content }
    login_form = page.forms.find do |form|
      form.fields.find { |field| field.name == "pl" && field.value == username }
    end
    login_form.pswd = password

    result = login_form.submit
    File.open("#{self.class}-#{Time.now.iso8601}-login_result.html", 'w') { |file| file << result.content }
    # errors = result.xpath("//p[text()='bad password/username combination.']")
    # raise RuntimeError(errors.map(&:text).join) unless errors.empty?

    result
  end

  def parse_table
    all_rows = enter_picks_page.xpath("//table/tr").take_while do |row|
      row.text && !row.text.strip.start_with?("Tie Breaker")
    end

    games = Game.games_for_season(season)
    all_rows.each_slice(9).flat_map do |rows|
      break if rows[0].text.strip.start_with?("Tie Breaker")
      parse_rows(rows, games)
    end
  end

  def parse_rows(rows, games)
    games = rows[0].xpath("td").drop(1).map { |td| { game: games.find { |game| game.bowl.name == Bowl.normalize_name(td.text) } } }
    rows[4].xpath("td").drop(1).each_slice(2).zip(games).each do |(visit, home), game|
      teams = [game[:game].visitor, game[:game].home]
      game[:visitor] = teams.find { |team| team.name == Team.normalize_name(visit.text) }
      game[:home] = teams.find { |team| team.name == Team.normalize_name(home.text) }
    end

    games
  end
end
