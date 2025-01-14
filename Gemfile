# frozen_string_literal: true

source "https://rubygems.org"

# Load environment variables
gem "dotenv-rails", require: "dotenv/load"

gem "aasm"
gem "activerecord-postgis-adapter", "~> 10.0"
gem "acts_as_list"
gem "appsignal"
gem "aws-sdk-cloudfront", require: false
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "business_time"
gem "commonmarker", "~> 0.23.10"
gem "daemons"
gem "dartsass-rails"
gem "devise"
gem "devise-two-factor"
gem "discard", "~> 1.4"
gem "faker", require: false
gem "faraday", "~> 2", require: false
gem "grover"
gem "holidays"
gem "i18n", "< 1.9"
gem "i18n-tasks"
gem "image_processing", "~> 1.12"
gem "jbuilder"
gem "jsbundling-rails"
gem "json_schemer"
gem "lograge", "~> 0.14.0"
gem "mail-notify"
gem "matrix"
gem "mini_magick"
gem "notifications-ruby-client"
gem "pagy"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 6"
gem "rack", "~> 3"
gem "rails", "~> 7.2"
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
gem "strong_migrations"
gem "strong_password", "~> 0.0.9"
gem "view_component"

# These gems are included to fix deprecation warnings
gem "csv"
gem "logger"
gem "ostruct"

# Gem for shared code across engines
gem "bops_core", path: "engines/bops_core"

gem "bops_admin", path: "engines/bops_admin"
gem "bops_api", path: "engines/bops_api"
gem "bops_config", path: "engines/bops_config"
gem "bops_consultees", path: "engines/bops_consultees"
gem "bops_uploads", path: "engines/bops_uploads"

group :development, :test do
  gem "brakeman", require: false
  gem "bullet"
  gem "erb_lint", require: false
  gem "guard", require: false
  gem "guard-cucumber", require: false
  gem "guard-rspec", require: false
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails"
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
  gem "email_spec"
  gem "factory_bot_rails"
  gem "openapi3_parser", require: false
  gem "webmock"
end
