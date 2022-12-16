require 'user'

namespace :user do
  task :create, [:email, :name, :nickname, :phone_number] =>  "db:load_config" do |_task, args|
    user = User.create!(
      email: args[:email], 
      name: args[:name], 
      nickname: args[:nickname], 
      phone_number: args[:phone_number]
    )
    puts "/add_participant?token=#{user.token}"
  end
end
