# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem "activerecord", "~> 7.0"
gem "aws-sdk-s3", "~> 1.60"
gem "clockwork", "~> 2.0"
gem "foreman", "~> 0.86"
gem "mechanize", "~> 2.7"
gem "rake"
gem "sinatra", "~> 2.0"
gem "sinatra-activerecord", "~> 2.0"
gem "sqlite3"
gem "unicorn", "~> 6.1.0"

group :development, :test do
  gem "pry"
  gem "rb-readline"
  gem "rspec"
  gem "vcr"
  gem "webmock"
end
