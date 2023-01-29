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
    Updatestatuss.perform(@season)
  end

  def update(now: Time.now)
    cbs_scores.scrape
    games.each do |game|
      next if game.game_time > (now + 300)
      status = cbs_scores.check_score(game)

      if status.team_mismatch?
        # record mismatches in a pending state, once approved, new team(s) will be swapped and the results can be applied
        GameChange.transaction do
          if status.visiting_team_mismatch?
            GameChange.where(
              game: game, 
              new_team: Team.where(name: Team.normalize_name(status.visitor_name)).first_or_create!, 
              previous_visiting_team: game.visitor
            ).first_or_create!
          end
          if status.home_team_mismatch?
            GameChange.where(
              game: game, 
              new_team: Team.where(name: Team.normalize_name(status.home_name)).first_or_create!,
              previous_visiting_team: game.home
            ).first_or_create!
          end
        end
      elsif status.missing? && now > (game.game_time + 1.day)
        update_completed(game, status)
      elsif status.in_progress?
        update_in_progress(game, status)
      elsif status.completed?
        update_completed(game, status)       
      end  
    end
  rescue => ex
    puts "Error scraping scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end

  private

  attr_reader :cbs_scores

  def games
    @season.games
  end

  def update_in_progress(game, status)
    Score.transaction do
      Score.where(
        game: game,
        team: game.teams.find { |team| team.name == Team.normalize_name(status.visitor_name) },
        quarter: status.quarter,
        time_remaining_seconds: status.remaining_secs,
        points: status.visitor_score
      ).first_or_create!
      Score.where(
        game: game,
        team: game.teams.find { |team| team.name == Team.normalize_name(status.home_name) },
        quarter: status.quarter,
        time_remaining_seconds: status.remaining_secs,
        points: status.home_score
      ).first_or_create!      
    end
  rescue StandardError => ex
    puts "Error updating in-progress scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end

  def update_completed(game, status)
    FinalScore.transaction do
      if status.cancelled?
        game.cancelled!
      elsif status.missing?
        game.missing!
      else
        FinalScore.where(game: game, team: game.teams.find { |team| team.name == Team.normalize_name(status.visitor_name) }).first_or_create! do |s|
          s.points = status.visitor_score
        end
        FinalScore.where(game: game, team: game.teams.find { |team| team.name == Team.normalize_name(status.home_name) }).first_or_create! do |s|
          s.points = status.home_score
        end
        game.finished!
      end     
    end
  rescue StandardError => ex
    puts "Error updating completed scores: #{ex.message} - #{ex.backtrace.join("\n")}"
  end
end
