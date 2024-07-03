# frozen_string_literal: true

require "capybara/rspec"

Capybara.add_selector(:planning_applications_status_tab) do
  xpath { "//*[@class='govuk-tabs__list']" }
end

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.args << "--headless"

  profile = Selenium::WebDriver::Firefox::Profile.new
  profile["network.dns.forceResolve"] = "127.0.0.1"
  options.profile = profile

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.before :all, type: :system do
    Capybara.automatic_label_click = true
    Capybara.enable_aria_label = true
    Capybara.ignore_hidden_elements = false
    Capybara.server = :puma, {Silent: true}
  end

  config.before type: :system do |example|
    driver = if example.metadata[:capybara] || example.metadata[:js]
      ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
      ENV.fetch("JS_DRIVER", "headless_firefox").to_sym
    else
      ENV.fetch("TEST_DRIVER", "rack_test").to_sym
    end

    driven_by driver

    Capybara.app_host = "http://planx.example.com"
  end
end
