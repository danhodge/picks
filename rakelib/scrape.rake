require 'season'
require 'cbs_schedule'
require 'fox_lines'

namespace :scrape do
  task schedule: "db:load_config" do
    CBSSchedule.new(Season.current).scrape_and_create
  end

  task lines: "db:load_config" do
    puts FoxLines.new(Season.current).scrape_and_create
  end
end
