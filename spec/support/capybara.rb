# frozen_string_literal: true

require "capybara/rspec"
require "rackup"

module Rack
  Handler = ::Rackup::Handler
end

download_path = Rails.root.join("tmp/downloads").to_s

Capybara.add_selector(:planning_applications_status_tab) do
  xpath { "//*[@class='govuk-tabs__list']" }
end

Capybara.add_selector(:open_accordion) do
  xpath { "//*[@class='govuk-accordion__section govuk-accordion__section--expanded']" }
end

Capybara.add_selector(:open_review_task) do
  xpath do
    [
      "//*[@class='bops-task-accordion__section bops-task-accordion__section--expanded']",
      "/div[@class='bops-task-accordion__section-header']",
      "/button/h3[@class='bops-task-accordion__section-heading']"
    ].join
  end
end

Capybara.add_selector(:autoselect_option) do
  xpath do |from, value|
    "//ul[@id='#{from.delete_prefix("#")}__listbox']/li[@role='option' and normalize-space(.)='#{value}']"
  end
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
