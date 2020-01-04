class Team < ActiveRecord::Base
  validates :name, presence: true

  PREFIXES = {
    "C." => "Central",
    "N." => "North",
    "E." => "Eastern",
    "W." => "Western",
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
    "Miami FL" => "Miami (FL)"
  }.freeze

  REVERSE_ABBREVIATIONS = {
    "Alabama Birmingham" => "UAB",
    "Florida International" => "FIU",
    "Southern Methodist" => "SMU",
    "Texas - San Antonio" => "UTSA",
    "UL Lafayette" => "Louisiana"
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
end
