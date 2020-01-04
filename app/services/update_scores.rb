require 'final_score'
require 'score'
require 'season'
require 'cbs_scores'
require 'update_results'

class UpdateScores
  def self.perform
    new.perform
  end

  def initialize(cbs_scores: CBSScores.new(Season.current))
    @cbs_scores = cbs_scores
  end

  def perform
    update
    UpdateResults.perform
  end

  def update
    _in_progress, completed = cbs_scores.scrape
    # Score.transaction do
    #   in_progress.each do |score|
    #     Score.where()
    #   end
    # end

    FinalScore.transaction do
      completed.each do |score|
        FinalScore.where(game: score[:game], team: score[:visitor][:team]).first_or_create! do |s|
          s.points = score[:visitor][:score]
        end
        FinalScore.where(game: score[:game], team: score[:home][:team]).first_or_create! do |s|
          s.points = score[:home][:score]
        end
      end
    end
  rescue => ex
    puts "Error scraping scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end

  private

  attr_reader :cbs_scores
end
