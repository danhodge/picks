require 'season'
require 'cbs_schedule'
require 'cbs_lines'
require 'export_participants'
require 'family_fun_schedule'
require 'fox_lines'
require 'update_results'
require 'update_scores'

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

  task update_scores: "db:load_config" do
    UpdateScores.perform(Season.current)
  end

  task export_participants: "db:load_config" do
    # write partipants to S3
    ExportParticipants.perform(Season.current)
    # write results to S3
    UpdateResults.perform(Season.current)
  end
end
