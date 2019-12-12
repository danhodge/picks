class Bowl < ActiveRecord::Base
  validates :name, presence: true
end
