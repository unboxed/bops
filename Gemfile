# frozen_string_literal: true

source "https://rubygems.org"

# Load environment variables
gem "dotenv-rails", require: "dotenv/rails-now"

gem "aasm"
gem "activerecord-postgis-adapter"
gem "after_commit_everywhere"
gem "aws-sdk-codedeploy", require: false
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "devise"
gem "faker", require: false
gem "faraday", require: false
gem "image_processing", "~> 1.2"
gem "jbuilder", "~> 2.7"
gem "mail-notify"
gem "mini_magick"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 4.1"
gem "pundit"
gem "rails", "~> 6.0.3"
gem "rswag-api"
gem "rswag-ui"
gem "webpacker", "~> 4.0"
gem "appsignal"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capybara"
  gem "factory_bot_rails"
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 4.0.0"
  gem "rswag-specs"
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop", require: false
  gem "selenium-webdriver"
  gem "simplecov", require: false
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "web-console", ">= 3.3.0"
end

group :test do
  gem "webmock"
end
