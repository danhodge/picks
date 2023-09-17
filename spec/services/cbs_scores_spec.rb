require 'cbs_scores'

RSpec.describe CBSScores do
  let(:season) { Season.create!(year: 2021) }
  let(:fenway) { Bowl.create!(name: "Fenway", city: "Boston", state: "MA") }

  describe "#check_score" do
    it "handles cancellations" do
      visitor = Team.create!(name: "SMU")
      home = Team.create!(name: "Virginia")
      game = Game.create!(
        bowl: fenway, 
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

    let(:arizona) { Bowl.create!(name: "Arizona", city: "Glendale", state: "AZ") }

    it "handles missing results" do
      visitor = Team.create!(name: "Boise State")
      home = Team.create!(name: "Central Michigan")
      game = Game.create!(
        bowl: arizona, 
        visitor: visitor, 
        home: home, 
        season: season, 
        game_time: "2021-12-31T21:30:00Z"
      )

      scores = CBSScores.new(season)

      VCR.use_cassette("scores_2021") do
        scores.scrape
        result = scores.check_score(game)
        expect(result).to be_missing
      end      
    end

    let(:sun) { Bowl.create!(name: "Sun", city: "El Paso", state: "TX") }

    it "handles team mismatches" do
      visitor = Team.create!(name: "Miami (FL)")
      home = Team.create!(name: "Washington State")
      game = Game.create!(
        bowl: sun, 
        visitor: visitor, 
        home: home, 
        season: season, 
        game_time: "2021-12-31T17:30:00Z"
      )

      scores = CBSScores.new(season)

      VCR.use_cassette("scores_2021") do
        scores.scrape
        result = scores.check_score(game)
        expect(result).to be_team_mismatch
        expect(result).to be_visiting_team_mismatch
      end
    end

    let(:music_city) { Bowl.create!(name: "Music City", city: "Nashville", state: "TN")  }

    it "handles overtime results; home/visitor switch" do
      visitor = Team.create!(name: "Purdue")
      home = Team.create!(name: "Tennessee")
      game = Game.create!(
        bowl: music_city, 
        visitor: visitor, 
        home: home, 
        season: season, 
        game_time: "2021-12-30T20:00:00Z"
      )

      scores = CBSScores.new(season)

      VCR.use_cassette("scores_2021") do
        scores.scrape
        result = scores.check_score(game)
        expect(result).to be_completed
        expect(result.visitor_score).to eq(48)
        expect(result.visitor_intermediate_scores).to eq([7, 16, 7, 15, 3])
        expect(result.home_score).to eq(45)
        expect(result.home_intermediate_scores).to eq([21, 0, 10, 14, 0])
      end
    end
  end
end