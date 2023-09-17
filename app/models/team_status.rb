class TeamStatus
  attr_reader :name, :score, :intermediate_scores
  
  def initialize(name, score, intermediate_scores)
    @name = name
    @score = score
    @intermediate_scores = intermediate_scores
  end
end