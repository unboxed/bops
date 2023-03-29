# frozen_string_literal: true

source "https://rubygems.org"

# Load environment variables
gem "dotenv-rails", require: "dotenv/rails-now"

gem "aasm"
gem "appsignal"
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "business_time"
gem "daemons"
gem "dartsass-rails"
gem "delayed_job_active_record"
gem "devise"
gem "devise-two-factor"
gem "faker", require: false
gem "faraday", require: false
gem "govuk_design_system_formbuilder"
gem "grover"
gem "i18n", "< 1.9"
gem "i18n-tasks"
gem "image_processing", "~> 1.12"
gem "jbuilder"
gem "jsbundling-rails"
gem "mail-notify"
gem "matrix"
gem "mini_magick"
gem "notifications-ruby-client"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 4"
gem "rails", "~> 7.0"
gem "rails_autolink"
gem "rswag-ui"
gem "sprockets-rails"
gem "stimulus-rails"
gem "strong_password", "~> 0.0.9"
gem "view_component"
gem "whenever"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "guard", require: false
  gem "guard-cucumber", require: false
  gem "guard-rspec", require: false
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 4.0.0"
  gem "rubocop", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "selenium-webdriver"
  gem "webdrivers", require: false
end

group :development do
  gem "foreman"
  gem "listen"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "cucumber-rails", require: false
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "openapi3_parser", require: false
  gem "webmock"
end
