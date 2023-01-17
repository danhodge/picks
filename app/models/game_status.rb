class GameStatus
  attr_accessor :status, :quarter, :remaining
  attr_reader :game_name, :home, :visitor

  delegate :name, :score, :intermediate_scores, to: :visitor, prefix: "visitor", allow_nil: false
  delegate :name, :score, :intermediate_scores, to: :home, prefix: "home", allow_nil: false

  def initialize(game_name, visitor, home)
    @game_name = game_name
    @visitor = visitor
    @home = home
  end

  def team_mismatches?
    visiting_team_mismatch? || home_team_mismatch?
  end

  def visiting_team_mismatch?
  end

  def home_team_mismatch?
  end

  def in_progress?
    return !completed?
  end

  def completed?
    return cancelled? || @status == "final" 
  end

  def cancelled?
    return @status == "cancelled"
  end
end