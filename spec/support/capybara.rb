# frozen_string_literal: true

download_path = Rails.root.join("tmp/downloads").to_s

Capybara.register_driver :chrome_headless do |app|
  Capybara::Selenium::Driver.load_selenium
  browser_options = ::Selenium::WebDriver::Chrome::Options.new
  browser_options.args << "--headless"
  browser_options.args << "--allow-insecure-localhost"
  browser_options.args << "--window-size=1280,960"
  browser_options.args << "--disable-gpu" if Gem.win_platform?
  browser_options.args << "--host-rules=MAP * 127.0.0.1"
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options).tap { |d| d.browser.download_path = download_path }
end

RSpec.configure do |config|
  config.before :all, type: :system do
    Capybara.automatic_label_click = true
    Capybara.enable_aria_label = true
    Capybara.ignore_hidden_elements = false
    Capybara.server = :puma, { Silent: true }
  end

  config.before type: :system do
    driven_by(ENV.fetch("JS_DRIVER", "chrome_headless").to_sym)

    host! "http://localhost"
  end
end
