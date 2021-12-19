class Bowl < ActiveRecord::Base
  validates :name, presence: true
  validates :city, :state, presence: true, unless: -> { self.class.championship?(name) }

  def self.championship?(name)
    name.downcase.squeeze(" ").include?("national championship")
  end

  def self.semifinal?(name)
    processed_name = name.downcase.squeeze(" ")
    processed_name.include?("playoff") && processed_name.include?("semifinal")
  end

  def self.semifinal_bowls(season)
    if season.year == 2021
      Bowl.where(name: %w(Cotton Orange))
    end
  end

  def self.normalize_name(name, season: Season.current)
    normalized = strip_sponsors(name.gsub(/ Bowl\z/, ''), season)

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
    elsif normalized == "Go Daddy"
      "Go Daddy"
    elsif normalized == "Armed Force"
      "Armed Forces"
    elsif normalized == "Dukes Mayo"
      "Duke's Mayo"
    elsif normalized == "Tony the Tiger"
      "Sun"
    elsif normalized == "Frisco Football Classic"
      "Frisco Classic"
    elsif normalized == "LA"
      "L.A."
    else
      normalized
    end
  end

  def self.strip_sponsors(name, season)
    tokens = name.split(" ")
    if (season.year < 2014) && ((tokens[0] == "Chick-fil-A")  || (tokens.take(2) == %w(Capital One)))
      # do not strip the sponsor prior to 2014
    elsif %w(AFR Gildan AutoNation Marmot SDCCU Popeyes Hyundai Zaxby FAM Chick-fil-A Goodyear BW3 Allstate AutoZone Valero).include?(tokens[0])
      tokens.shift
    elsif (season.year < 2017) && (tokens.take(2) == %w(Camping World))
      tokens.shift(2)
    elsif tokens.take(3) == %w(Nova Home Loans)
      tokens.shift(3)
    elsif [
      %w(Royal Purple),
      %w(Raycom Media),
      %w(RL Carriers),
      %w(New Era),
      %w(Lockheed Martin),
      %w(AdoCare V100),
      %w(Capital One),
      %w(Battle Frog),
      %w(Motel 6),
      %w(Jimmy Kimmel)
    ].include?(tokens.take(2))
      tokens.shift(2)
    end

    tokens.join(" ")
  end
end
