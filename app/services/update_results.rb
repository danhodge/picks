require 'game'
require 'aws-sdk-s3'

class UpdateResults
  def self.perform(season)
    new(season: season).perform
  end

  def initialize(season: Season.current, client: Aws::S3::Client.new(region: 'us-east-1'))
    @season = season
    @client = client
  end

  def build_results
    {
      "results" => build_game_results,
      "changes" => build_changes,
      "scoring" => build_scores
    }
  end

  def build_game_results
    Game.games_for_season(season).select(&:completed?).map do |game|
      outcome = game.game_outcome
      status = 
        if outcome.cancelled?
          "cancelled"
        elsif outcome.forfeited?
          "forfeited"
        else
          "completed"
        end
      
      results = { status: status }
      if outcome.forfeited?
        results[:forfeited_by] = (game.home_forfeit? ? game.home : game.visitor).id
      end

      if awarded = outcome.points_awarded_to
        results[:points_awarded_to] = awarded.id
      end

      if outcome.completed?
        results[:final_scores] = game.final_scores.map { |score| [score.team_id, score.points] }.to_h
      end

      results
    end
  end

  def build_changes
    Game
      .games_for_season(season)
      .includes(:accepted_game_changes)
      .select(&:completed?)
      .select { |game| game.accepted_game_changes.present? }
      .each_with_object({}) do |game, changes|
        changes[game.id] = game.accepted_game_changes.map do |change|
          {
            original_team_id: change.previous_visiting_team_id || change.previous_home_team_id,
            new_team_id: change.new_team_id
          }
        end
      end
  end

  def build_scores
    Participant
      .participants_for_season(season)
      .each_with_object({}) do |participant, scores|
        correct, incorrect = participant.picks.completed.partition { |pick| pick.correct? }
        points = {
          won: correct.map(&:points).sum,
          lost: incorrect.map(&:points).sum,
        }

        points[:remaining] = season.total_points - (points[:won] + points[:lost])
        unless points[:won].zero? && points[:lost].zero?
          points[:average] = ((points[:won] / (points[:won] + points[:lost]).to_f) * 100).round(2)
        end

        scores[participant.id] = { 
          points: points, 
          games: { 
            won: correct.count, 
            lost: incorrect.count 
          } 
        }
      end
  end

  def perform
    resp = client.put_object(
      acl: "public-read",
      bucket: "danhodge-cfb",
      key: "#{season.year}/results_#{season.year}.json",
      body: build_results.to_json
    )
    puts "Updated s3://danhodge-cfb/#{season.year}/results_#{season.year}.json - #{resp}"
  end

  private

  attr_reader :season, :client
end
