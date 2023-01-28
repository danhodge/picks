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

  def remaining_secs
    return 0 unless in_progress?
    
    if self.remaining
      mins, secs = self.remaining.split(":").map(&:to_i)
      secs + mins * 60
    else
      0
    end
  end

  def team_mismatch?
    visiting_team_mismatch? || home_team_mismatch?
  end

  def visiting_team_mismatch?
    @status == "visiting_team_mismatch"
  end

  def home_team_mismatch?
    @status == "home_team_mismatch"
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

  def missing?
    return @status == "missing"
  end

  def swap_teams!
    prev_home = @home
    @home = @visitor
    @visitor = prev_home
  end
end


# quarter = score[:status][:quarter].gsub(/[^\d]/, "")
#       remaining_secs =
#         if (remaining = score[:status][:remaining])
#           mins, secs = remaining.split(":").map(&:to_i)
#           secs + mins * 60
#         else
#           0
#         end
