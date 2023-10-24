# frozen_string_literal: true

require "capybara/rspec"

download_path = Rails.root.join("tmp/downloads").to_s

Capybara.add_selector(:planning_applications_status_tab) do
  xpath { "//*[@id='planning_applications_statusTab']" }
end

Capybara.register_driver :chrome_headless do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless"
  browser_options.args << "--no-sandbox"
  browser_options.args << "--allow-insecure-localhost"
  browser_options.args << "--window-size=1280,2800"
  browser_options.args << "--disable-gpu" if Gem.win_platform?
  browser_options.args << "--disable-dev-shm-usage"
  browser_options.args << "--host-rules=MAP * 127.0.0.1"

  if Gem::Platform.local.os == "darwin" && !(File.exist? "/Applications/Google Chrome for Testing.app")
    browser_options.binary = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
  end

  if Gem::Platform.local.os != "darwin"
    # Probably Docker/GHA
    %w[/usr/local/bin /usr/bin].each do |path|
      driver_path = "#{path}/chromedriver"
      if File.exist? driver_path
        Selenium::WebDriver::Chrome::Service.driver_path = driver_path
        break
      end
    end
  end

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

  config.before type: :system do
    driven_by(ENV.fetch("JS_DRIVER", "chrome_headless").to_sym)
    Capybara.app_host = "http://planx.example.com"
  end
end
