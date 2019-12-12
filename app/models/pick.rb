class Pick < ActiveRecord::Base
  belongs_to :season
  belongs_to :participant
  belongs_to :game
  belongs_to :team

  validates :points, presence: true
end
