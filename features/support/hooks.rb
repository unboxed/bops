# frozen_string_literal: true

require Rails.root.join("spec/support/notify_mock")

Before do
  Rails.configuration.use_new_sidebar_layout = false
end

Before do
  Rails.application.load_seed

  LocalAuthority.update_all(
    notify_api_key: "fake-c2a32a67-f437-46cd-9364-483d2cc4c43f-523849d3-ca3b-4c12-b11a-09ed7d86de2e",
    email_reply_to_id: "4896bb50-4f4c-4b4d-ad67-2caddddde125",
    email_template_id: "c56d9346-02be-4812-af6b-e254269c98d7",
    sms_template_id: "296467e7-6723-465a-86b9-eb8c81a9199c",
    letter_template_id: "af0b1749-b2b2-4517-9b76-17226fc10f7a"
  )
end

Before("@javascript") do
  next unless page.driver.respond_to?(:invalid_element_errors)

  unless page.driver.invalid_element_errors.include?(Selenium::WebDriver::Error::UnknownError)
    page.driver.invalid_element_errors << Selenium::WebDriver::Error::UnknownError
  end
end

Before do
  stub_request(:post, NotifyMock.url).to_rack(NotifyMock.app)
end
