require 'cbs_games'

RSpec.describe CBSGames do
  describe "#each" do
    it "finds statuses for all of the games" do
      page = Mechanize::Page.new(nil, nil, File.read("spec/fixtures/cbs/scores_21.html"), 200,  Mechanize.new)
      games = described_class.new(page).each.to_a

      expect(games.length).to eq(9)
      expect(games.filter(&:cancelled?).length).to eq(2)
    end
  end
end