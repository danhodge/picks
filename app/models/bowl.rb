class Bowl < ActiveRecord::Base
  validates :name, presence: true
  validates :city, :state, presence: true, unless: -> { self.class.championship?(name) }

  def self.championship?(name)
    name.downcase.squeeze(" ").include?("national championship")
  end
end
