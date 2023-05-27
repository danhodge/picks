require 'deploy'

namespace :deploy do
  desc "Deploys the frontend to S3"
  task :site, [:bucket] do |_task, args|
    raise "Bucket name must be provided" unless args[:bucket]

    # TODO: rebuild frontend first
    deployer = Deploy.new
    deployer.deploy_site(args[:bucket])
  end
end