# frozen_string_literal: true

# Faker is in the default Gemfile group and since we don't want to

# This means we need to explicitly require it here for it to be
# available in our specs.
require "faker"
require 'webmock/rspec'

WebMock.disable_net_connect!(allow_localhost: true)

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus

  config.disable_monkey_patching!

  if config.files_to_run.one?
    config.default_formatter = "doc"
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do |example|
    @local_planning_authority = LocalPlanningAuthority.create!(name: 'Test Authority', subdomain: 'test')
    Capybara.default_host = "http://#{@local_planning_authority.subdomain}.example.com"
    if example.metadata[:type] == :request || example.metadata[:type] == :system
      # Set the `test_tenant` value for integration tests
      ActsAsTenant.test_tenant = @local_planning_authority
    else
      # Otherwise just use current_tenant
      ActsAsTenant.current_tenant = @local_planning_authority
    end
  end

  config.after(:each) do |example|
    # Clear any tenancy that might have been set
    ActsAsTenant.current_tenant = nil
    ActsAsTenant.test_tenant = nil
    Capybara.default_host = "http://www.example.com"
    @local_planning_authority.destroy!
  end
end
