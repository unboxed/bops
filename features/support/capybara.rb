# frozen_string_literal: true

Capybara.server = :puma, { Silent: true }

Capybara.register_driver :firefox_headless do |app|
  options = ::Selenium::WebDriver::Firefox::Options.new
  options.args << "--headless"

  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.javascript_driver = ENV.fetch("JS_DRIVER", "firefox_headless").to_sym
Capybara.automatic_label_click = true
