require 'cbs_scores'

RSpec.describe CBSScores do
  describe "#check_score" do
    it "works" do
      season = Season.create!(year: 2021)
      bowl = Bowl.create!(name: "Fenway", city: "Boston", state: "MA")
      visitor = Team.create!(name: "SMU")
      home = Team.create!(name: "Virginia")
      game = Game.create!(
        bowl: bowl, 
        visitor: visitor, 
        home: home, 
        season: season, 
        game_time: "2021-12-29T16:00:00Z"
      )

      scores = CBSScores.new(season)

      VCR.use_cassette("scores_2021") do
        scores.scrape
        result = scores.check_score(game)
        expect(result).to be_cancelled
      end
    end
  end
end