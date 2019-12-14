require 'user'

namespace :user do
  task :create, [:email] =>  "db:load_config" do |_task, args|
    user = User.create!(email: args[:email])
    puts "/add_participant?token=#{user.token}"
  end
end
