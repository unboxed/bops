# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.5"

gem "activerecord-postgis-adapter"
gem "aws-sdk-s3", require: false
gem "bootsnap", ">= 1.4.2", require: false
gem "devise"
gem "faker", require: false
gem "image_processing", "~> 1.2"
gem "jbuilder", "~> 2.7"
gem "mail-notify"
gem "mini_magick"
gem "pg", ">= 0.18", "< 2.0"
gem "puma", "~> 4.1"
gem "pundit"
gem "rails", "~> 6.0.3"
gem "webpacker", "~> 4.0"

group :development, :test do
  gem "brakeman", require: false
  gem "bundler-audit", require: false
  gem "byebug", platforms: [:mri, :mingw, :x64_mingw]
  gem "capybara"
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

group :test do
  gem "webmock"
end

gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]
