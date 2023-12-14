# frozen_string_literal: true

source "https://rubygems.org"

# Load environment variables
gem "dotenv-rails", require: "dotenv/rails-now"

gem "aasm"
gem "activerecord-postgis-adapter"
gem "appsignal"
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "business_time"
gem "daemons"
gem "dartsass-rails"
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
gem "json_schemer"
gem "mail-notify"
gem "matrix"
gem "mini_magick"
gem "notifications-ruby-client"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 5"
gem "rails", "~> 7.0"
gem "rails_autolink"
gem "rgeo"
gem "rgeo-geojson"
gem "rswag-api"
gem "rswag-ui"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "sprockets-rails"
gem "stimulus-rails"
gem "store_model"
gem "strong_password", "~> 0.0.9"
gem "view_component"

gem "bops_api", path: "engines/bops_api"

group :development, :test do
  gem "brakeman", require: false
  gem "bullet"
  gem "guard", require: false
  gem "guard-cucumber", require: false
  gem "guard-rspec", require: false
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 4.0.0"
  gem "rswag-specs", require: false
  gem "standard", "~> 1.31", require: false
  gem "standard-custom", require: false
  gem "standard-performance", require: false
  gem "standard-rails", require: false
  gem "selenium-webdriver"
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
