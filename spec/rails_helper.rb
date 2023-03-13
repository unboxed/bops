# frozen_string_literal: true

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

require "webdrivers"

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

ActiveJob::Base.queue_adapter = :test

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  config.fixture_path = Rails.root.join("spec/fixtures")
  config.file_fixture_path = Rails.root.join("spec/fixtures/files")

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!

  config.include Devise::Test::IntegrationHelpers, type: :request

  config.before type: :request do
    host!("planx.example.com")
  end

  config.include(ActiveJob::TestHelper)
  config.include(SystemSpecHelpers)
  config.include Rails.application.routes.url_helpers
end
