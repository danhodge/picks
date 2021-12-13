require 'season'
require 'cbs_schedule'
require 'cbs_lines'
require 'export_participants'
require 'family_fun_schedule'
require 'fox_lines'

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

  task export_participants: "db:load_config" do
    ExportParticipants.new(Season.current).perform
  end
end
