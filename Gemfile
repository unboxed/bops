# frozen_string_literal: true

source "https://rubygems.org"

# Load environment variables
gem "dotenv-rails", require: "dotenv/rails-now"

gem "aasm"
gem "activerecord-postgis-adapter"
gem "after_commit_everywhere"
gem "appsignal"
gem "aws-sdk-codedeploy", require: false
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "business_time"
gem "devise"
gem "faker", require: false
gem "faraday", require: false
gem "govuk_design_system_formbuilder"
gem "image_processing", "~> 1.2"
gem "jbuilder"
gem "mail-notify"
gem "mini_magick"
gem "pdfkit"
gem "pg", ">= 0.18", "< 2.0"
gem "puma"
gem "rails", "~> 6.1.3.2"
gem "rswag-ui"
gem "webpacker", "~> 5.2", ">= 5.2.1"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "capybara"
  gem "factory_bot_rails"
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 4.0.0"
  gem "rubocop", require: false
  gem "rubocop-govuk", "4.0.0"
  gem "selenium-webdriver"
  gem "simplecov", require: false
end

group :development do
  gem "listen"
  gem "web-console"
end

group :test do
  gem "openapi3_parser"
  gem "webmock"
end
