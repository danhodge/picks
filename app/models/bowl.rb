class Bowl < ActiveRecord::Base
  validates :name, presence: true
  validates :city, :state, presence: true, unless: -> { self.class.championship?(name) }

  def self.championship?(name)
    name.downcase.squeeze(" ").include?("national championship")
  end

  def self.normalize_name(name)
    normalized = strip_sponsors(name.gsub(/ Bowl\z/, ''))

    if normalized == "Famous Idaho Potato" || normalized == "Potato"
      "Idaho Potato"
    elsif normalized == "Lending Tree"
      "LendingTree"
    elsif normalized == "Camelia"
      "Camellia"
    elsif normalized == "First Responders"
      "First Responder"
    elsif normalized == "Taxslayer" || normalized == "Tax Slayer"
      "TaxSlayer"
    elsif normalized == "St. Pete"
      "St. Petersburg"
    else
      normalized
    end
  end

  def self.strip_sponsors(name)
    tokens = name.split(" ")
    if %w(AFR Gildan AutoNation Marmot SDCCU Popeyes Hyundai Zaxby FAM Chick-fil-A Goodyear BW3 Allstate AutoZone Valero).include?(tokens[0])
      tokens.shift
    elsif [
      %w(Royal Purple),
      %w(Raycom Media),
      %w(RL Carriers),
      %w(New Era),
      %w(Camping World),
      %w(Lockheed Martin),
      %w(AdoCare V100),
      %w(Capital One),
      %w(Battle Frog),
      %w(Motel 6)
    ].include?(tokens.take(2))
      tokens.shift(2)
    elsif tokens.take(3) == %w(Nova Home Loans)
      tokens.shift(3)
    end

    tokens.join(" ")
  end

  def name=(name)
    super(self.class.normalize_name(name))
  end
end
