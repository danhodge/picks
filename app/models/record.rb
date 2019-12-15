class Record < ActiveRecord::Base
  belongs_to :season
  belongs_to :team

  validates :wins, :losses, presence: true
end
