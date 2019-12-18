class Bowl < ActiveRecord::Base
  validates :name, presence: true
  validates :city, :state, presence: true, unless: -> { self.class.championship?(name) }

  def self.championship?(name)
    name.downcase.squeeze(" ").include?("national championship")
  end

  def self.normalize_name(name)
    normalized = name.gsub(/ Bowl\z/, '')
    if normalized == "Famous Idaho Potato"
      "Idaho Potato"
    else
      normalized
    end
  end

  def name=(name)
    super(self.class.normalize_name(name))
  end
end
