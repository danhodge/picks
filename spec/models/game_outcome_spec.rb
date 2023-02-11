RSpec.describe GameOutcome do
  let(:season) { Season.current }
  let(:bowl) { Bowl.create!(name: "Fenway", city: "Boston", state: "MA") }
  let(:visitor) { Team.create!(name: "Team 1") }
  let(:home) { Team.create!(name: "Team 2") }
  let(:game) { Game.create!(bowl: bowl, visitor: visitor, home: home, season: season, game_time: Time.now) }

  context "incomplete" do
    let(:outcome) { GameOutcome.incomplete }

    it "declares no winner or loser" do
      expect(outcome.winner).to be_nil
      expect(outcome.loser).to be_nil
    end

    it "awards no points" do
      expect(outcome.points_awarded_to).to be_nil
    end
  end

  context "cancelled" do
    let(:outcome) { GameOutcome.cancelled }

    before do
      game.abandoned!
    end

    it "declares no winner or loser" do
      expect(outcome.winner).to be_nil
      expect(outcome.loser).to be_nil
    end

    it "awards no points" do
      expect(outcome.points_awarded_to).to be_nil
    end
  end

  context "completed" do
    let(:outcome) { GameOutcome.completed(game) }

    before do
      FinalScore.where(game: game, team: home).first_or_create!(points: 9)
      FinalScore.where(game: game, team: visitor).first_or_create!(points: 4)
      game.finished!
    end

    it "declares winner & loser based on final scores" do
      expect(outcome.winner).to eq(home)
      expect(outcome.loser).to eq(visitor)
    end

    it "awards points based on the final score" do
      expect(outcome.points_awarded_to).to eq(outcome.winner)
    end
  end

  context "completed_with_change" do
    let(:outcome) { GameOutcome.completed_with_change(game) }

    before do
      FinalScore.where(game: game, team: home).first_or_create!(points: 9)
      FinalScore.where(game: game, team: visitor).first_or_create!(points: 4)
      game.finished!
    end

    it "declares winner & loser based on final scores" do
      expect(outcome.winner).to eq(home)
      expect(outcome.loser).to eq(visitor)
    end

    let(:other_team) { Team.create!(name: "Other") }

    it "awards points to the winning team if they were unchanged" do
      GameChange.where(
        game: game, 
        new_team: visitor, 
        previous_visiting_team: other_team, 
        status: "accepted"
      ).first_or_create!
      expect(outcome.points_awarded_to).to eq(home)
    end

    it "awards points to the losing team if they were unchanged" do
      GameChange.where(
        game: game, 
        new_team: home, 
        previous_home_team: other_team,
        status: "accepted"
      ).first_or_create!
      expect(outcome.points_awarded_to).to eq(visitor)
    end
  end

  context "completed_with_changes" do
    let(:outcome) { GameOutcome.completed_with_changes(game) }

    before do
      FinalScore.where(game: game, team: home).first_or_create!(points: 9)
      FinalScore.where(game: game, team: visitor).first_or_create!(points: 4)
      game.finished!
    end

    let(:other_team1) { Team.create!(name: "Other 1") }
    let(:other_team2) { Team.create!(name: "Other 2") }

    it "declares winner & loser based on final scores" do
      GameChange.where(
        game: game, 
        new_team: visitor, 
        previous_visiting_team: other_team1, 
        status: "accepted"
      ).first_or_create!
      GameChange.where(
        game: game, 
        new_team: home, 
        previous_home_team: other_team2, 
        status: "accepted"
      ).first_or_create!

      expect(outcome.winner).to eq(home)
      expect(outcome.loser).to eq(visitor)
    end

    it "awards no points" do
      expect(outcome.points_awarded_to).to be_nil
    end
  end

  context "forfeited" do
    let(:outcome) { GameOutcome.forfeited(game) }

    before do
      game.home_forfeit!
    end

    it "declares no winner or loser" do
      expect(outcome.winner).to be_nil
      expect(outcome.loser).to be_nil
    end

    it "awards points to the team that did not forfeit" do
      expect(outcome.points_awarded_to).to eq(visitor)
    end
  end
end