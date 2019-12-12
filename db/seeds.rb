require 'models'

User.create!(email: 'dev@example.com')

season = Season.create!(year: 2019)
motor_city = Bowl.create!(name: "Motor City", city: "Detroit", state: "MI")
aloha = Bowl.create!(name: "Aloha", city: "Honolulu", state: "HI")

t = Team.create!(name: "Toledo")
uiuc = Team.create!(name: "Illinois")
fsu = Team.create!(name: "Florida State")
bsu = Team.create!(name: "Boise State")

Game.create!(season: season, bowl: motor_city, visitor: t, home: uiuc, point_spread: -3.4, game_time: "2019-12-27T15:00:00-05:00")
Game.create!(season: season, bowl: aloha, visitor: fsu, home: bsu, point_spread: 8, game_time: "2019-12-26T12:00:00-05:00")
