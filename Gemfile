# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.5"

gem "bootsnap", ">= 1.4.2", require: false
gem "devise"
gem "jbuilder", "~> 2.7"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 4.1"
gem "rails", "~> 6.0.2"
gem "webpacker", "~> 4.0"

group :development, :test do
  gem "brakeman", require: false
  gem "bundle-audit", require: false
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capybara"
  gem "capybara-screenshot"
  gem "factory_bot_rails"
  gem "pry-byebug"
  gem "rails-controller-testing"
  gem "rspec-rails", "~> 4.0.0"
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

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
