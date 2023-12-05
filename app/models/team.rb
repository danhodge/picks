class Team < ActiveRecord::Base
  has_many :records

  validates :name, presence: true

  PREFIXES = {
    "C." => "Central",
    "N." => "North",
    "E." => "Eastern",
    "W." => "Western",
    "S." => "South",
    "La." => "Louisiana",
    "Ga." => "Georgia",
    "LA" => "Louisiana",
    "Wash." => "Washington",
    "Miss." => "Mississippi"
  }.freeze

  SUFFIXES = {
    "St." => "State"
  }.freeze

  ABBREVIATIONS = {
    "App. St." => "Appalachian State",
    "FAU" => "Florida Atlantic",
    "CMU" => "Central Michigan",
    "MSU" => "Michigan State",
    "Middle Tennessee" => "Middle Tennessee State",
    "Miami FL" => "Miami (FL)",
    "Miami-OH" => "Miami (OH)",
    "Miami" => "Miami (FL)",
    "MTSU" => "Middle Tennessee State",
    "Middle Tenn." => "Middle Tennessee State",
    "C. Carolina" => "Coastal Carolina",
    "N. Illinois" => "Northern Illinois",
    "App. State" => "Appalachian State",
    "App State" => "Appalachian State",
    "NIU" => "Northern Illinois",
    "ECU" => "East Carolina",
    "UNC" => "North Carolina",
    "Pitt" => "Pittsburgh",
    "So. Miss" => "Southern Miss",
    "C. Michigan" => "Central Michigan",
    "Cal" => "California"
  }.freeze

  REVERSE_ABBREVIATIONS = {
    "Alabama Birmingham" => "UAB",
    "Florida International" => "FIU",
    "Southern Methodist" => "SMU",
    "Texas - San Antonio" => "UTSA",
    "UL Lafayette" => "Louisiana",
    "LA - Lafayette" => "Louisiana",
    "Louisiana Lafayette" => "Louisiana",
    "Central Florida" => "UCF",
    "Mississippi" => "Ole Miss",
    "Miami Florida" => "Miami (FL)",
    "Miami Ohio" => "Miami (OH)",
    "Southern Mississippi" => "Southern Miss"
  }.freeze

  STATES = {
    "Ohio" => "OH",
    "Fla." => "FL"
  }.freeze

  def self.normalize_name(name)
    tokens = name.split(" ")

    if ABBREVIATIONS.key?(name)
      return ABBREVIATIONS[name]
    end

    if REVERSE_ABBREVIATIONS.key?(name)
      return REVERSE_ABBREVIATIONS[name]
    end

    if tokens.count > 1 && PREFIXES.key?(tokens[0])
      tokens[0] = PREFIXES[tokens[0]]
    end

    if tokens.count > 1 && SUFFIXES.key?(tokens[-1])
      tokens[-1] = SUFFIXES[tokens[-1]]
    end

    if tokens.count > 1 && tokens[-1].start_with?('(') && tokens[-1].end_with?(')') && STATES.key?(tokens[-1][1..-2])
      tokens[-1] = "(#{STATES[tokens[-1][1..-2]]})"
    end

    corrected = tokens.map do |token|
      if token == "Flordia"
        "Florida"
      else
        token
      end
    end

    corrected.join(" ")
  end

  def name=(name)
    super(self.class.normalize_name(name))
  end

  def record(season = Season.current)
    records.where(season: season).first
  end
end
