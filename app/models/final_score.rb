class FinalScore < ActiveRecord::Base
  belongs_to :game
  belongs_to :team

  validates :points, presence: true
end
