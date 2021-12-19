require 'final_score'
require 'score'
require 'season'
require 'cbs_scores'
require 'update_results'

class UpdateScores
  def self.perform(season)
    new(season: season).perform
  end

  def initialize(season: Season.current, cbs_scores: nil)
    @season = season
    @cbs_scores = cbs_scores || CBSScores.new(season)
  end

  def perform
    update
    UpdateResults.perform(@season)
  end

  def update
    in_progress, completed = cbs_scores.scrape

    update_in_progress(in_progress)
    update_completed(completed)
  rescue => ex
    puts "Error scraping scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end

  private

  attr_reader :cbs_scores

  def update_in_progress(in_progress)
    Score.transaction do
      in_progress.each do |score|
        quarter = score[:status][:quarter].gsub(/[^\d]/, "")
        remaining_secs =
          if (remaining = score[:status][:remaining])
            mins, secs = remaining.split(":").map(&:to_i)
            secs + mins * 60
          else
            0
          end

        Score.where(
          game: score[:game],
          team: score[:visitor][:team],
          quarter: quarter,
          time_remaining_seconds: remaining_secs,
          points: score[:visitor][:score]
        ).first_or_create!
        Score.where(
          game: score[:game],
          team: score[:home][:team],
          quarter: quarter,
          time_remaining_seconds: remaining_secs,
          points: score[:home][:score]
        ).first_or_create!
      end
    end
  rescue StandardError => ex
    puts "Error updating in-progress scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end

  def update_completed(completed)
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
  rescue StandardError => ex
    puts "Error updating completed scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end
end
