require 'season'
require 'cbs_schedule'
require 'cbs_lines'
require 'export_participants'
require 'family_fun_schedule'
require 'fox_lines'
require 'update_results'
require 'update_scores'
require 'update_seasons'

namespace :scrape do
  task schedule: "db:load_config" do
    CBSSchedule.new(Season.current).scrape_and_create
  end

  task family_fun_schedule: "db:load_config" do
    FamilyFunSchedule.scrape(Season.current)
  end

  task lines: "db:load_config" do
    FoxLines.new(Season.current).scrape_and_create
  end

  task cbs_lines: "db:load_config" do
    CBSLines.scrape_and_create(Season.current)
  end

  task :update_scores, [:season] => "db:load_config" do |_task, args|
    season = args.key?(:season) ? Season.find_by!(year: args[:season]) : Season.current
    UpdateScores.perform(season)
  end

  task :export_participants, [:season] => "db:load_config" do |_task, args|
    season = args.key?(:season) ? Season.find_by!(year: args[:season]) : Season.current
    # write partipants to S3
    ExportParticipants.perform(season)
    # write results to S3
    UpdateResults.perform(season)
  end

  task update_seasons: "db:load_config" do
    UpdateSeasons.perform()
  end
end
