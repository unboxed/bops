# frozen_string_literal: true

Capybara.server = :puma, { Silent: true }

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

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: browser_options)
end

Capybara.javascript_driver = ENV.fetch("JS_DRIVER", "chrome_headless").to_sym
Capybara.automatic_label_click = true
