# frozen_string_literal: true

require "capybara/rspec"
require "rackup"

module Rack
  Handler = ::Rackup::Handler
end

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
  download_dir = Rails.root.join("tmp/downloads")
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless=new"
  browser_options.args << "--no-sandbox"
  browser_options.args << "--allow-insecure-localhost"
  browser_options.args << "--window-size=1280,2800"
  browser_options.args << "--disable-gpu" if Gem.win_platform?
  browser_options.args << "--disable-dev-shm-usage"
  browser_options.args << "--host-rules=MAP * 127.0.0.1"

  browser_options.add_preference(:download, {
    prompt_for_download: false,
    default_directory: download_dir.to_s
  })

  browser_options.add_option("goog:loggingPrefs", {browser: "ALL"})

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

RSpec.configure do |config|
  config.include ViewComponent::TestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.before :all, type: :system do
    Capybara.automatic_label_click = true
    Capybara.enable_aria_label = true
    Capybara.ignore_hidden_elements = false
    Capybara.server = :puma, {Silent: true}
    Capybara.default_max_wait_time = 5
  end

  config.before type: :system do |example|
    driver = if example.metadata[:capybara] || example.metadata[:js]
      ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
    else
      ENV.fetch("TEST_DRIVER", "rack_test").to_sym
    end

    driven_by driver

    Capybara.app_host = "http://planx.bops.services"

    if page.driver.respond_to?(:invalid_element_errors)
      unless page.driver.invalid_element_errors.include?(Selenium::WebDriver::Error::UnknownError)
        page.driver.invalid_element_errors << Selenium::WebDriver::Error::UnknownError
      end
    end

    if page.driver.browser.respond_to?(:download_path=)
      page.driver.browser.download_path = downloads_path

      FileUtils.rm_rf(downloads_path)
      FileUtils.mkdir_p(downloads_path)
    end
  end
end
