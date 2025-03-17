# frozen_string_literal: true

Before do
  Rails.application.load_seed
end

Before("@javascript") do
  next unless page.driver.respond_to?(:invalid_element_errors)

  unless page.driver.invalid_element_errors.include?(Selenium::WebDriver::Error::UnknownError)
    page.driver.invalid_element_errors << Selenium::WebDriver::Error::UnknownError
  end
end
