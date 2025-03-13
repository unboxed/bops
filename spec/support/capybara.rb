# frozen_string_literal: true

require "capybara/rspec"
require "rackup"

module Rack
  Handler = ::Rackup::Handler
end

module Capybara::Selenium::Driver::ChromeDriver
  def reset!
    # Use instance variable directly so we avoid starting the browser just to reset the session
    return unless @browser

    handle = browser.window_handle # Only fetch window handle once
    switch_to_window(handle) # Should already be there, but ensure everything agrees
    (window_handles - [handle]).each { |win| close_window(win) } # Close every window handle but the current one.
    return super if chromedriver_version < 73

    timer = Capybara::Helpers.timer(expire_in: 10)
    begin
      clear_storage unless uniform_storage_clear?
      @browser.navigate.to("about:blank")
      wait_for_empty_page(timer)
    rescue *unhandled_alert_errors
      accept_unhandled_reset_alert
      retry
    end
    execute_cdp("Storage.clearDataForOrigin", origin: "*", storageTypes: storage_types_to_clear)
  end
end

download_path = Rails.root.join("tmp/downloads").to_s

Capybara.add_selector(:planning_applications_status_tab) do
  xpath { "//*[@class='govuk-tabs__list']" }
end

Capybara.register_driver :chrome_headless do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless=new"
  browser_options.args << "--no-sandbox"
  browser_options.args << "--allow-insecure-localhost"
  browser_options.args << "--window-size=1280,2800"
  browser_options.args << "--disable-gpu" if Gem.win_platform?
  browser_options.args << "--disable-dev-shm-usage"
  browser_options.args << "--host-rules=MAP * 127.0.0.1"

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options).tap do |d|
    d.browser.download_path = download_path
  end
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
    else
      ENV.fetch("TEST_DRIVER", "rack_test").to_sym
    end

    driven_by driver

    Capybara.app_host = "http://planx.example.com"
  end
end
