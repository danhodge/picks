RSpec.describe Game do
  it "works" do
    expect(Season.all.size).to be_zero
    Season.create!(year: 2022)
    expect(Season.all.size).to eq(1)
  end
end