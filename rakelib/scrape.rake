require 'season'
require 'cbs_schedule'

namespace :scrape do
  task schedule: "db:load_config" do
    CBSSchedule.new(Season.current).scrape
  end
end