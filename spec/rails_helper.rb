# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

if ENV['RAILS_ENV'] == 'test'
  require 'simplecov'
  SimpleCov.start 'rails'
  puts "required simplecov"
end

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "webmock/rspec"

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/spec/fixtures"
  config.file_fixture_path = "#{::Rails.root}/spec/fixtures/files"

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before(:each) do |example|
    @default_local_authority = LocalAuthority.find_or_create_by!(name: 'Default Authority', subdomain: 'default')
    if example.metadata[:type] == :request
      host! "default.example.com"
    elsif example.metadata[:type] == :system
      host! "http://default.example.com"
    end
  end
end
