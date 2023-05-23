# frozen_string_literal: true

module NotifyHelper
  BASE_URL = "https://api.notifications.service.gov.uk/v2/notifications/"
  SMS_URL = "#{BASE_URL}sms".freeze
  LETTER_URL = "#{BASE_URL}letter".freeze

  def stub_any_post_sms_notification
    stub_request(:post, /#{BASE_URL}.*/o)
  end

  def sms_notification_api_response(status, body = "{}")
    status = Rack::Utils.status_code(status)

    { status:, body: }
  end

  def stub_post_sms_notification(phone_number:, otp:, status:)
    stub_request(:post, SMS_URL)
      .with(
        body: {
          template_id: "701e32b3-2c8c-4c16-9a1b-c883ef6aedee",
          phone_number:,
          personalisation: {
            otp:
          }
        }.to_json
      )
      .to_return(
        status:,
        body: "{}"
      )
  end

  def stub_send_letter(address:, message:, status:)
    stub_request(:post, LETTER_URL)
      .with(
        body: {
          template_id: "701e32b3-2c8c-4c16-9a1b-c883ef6aedee",
          personalisation: {
            address:,
            message:
          }
        }.to_json
      )
      .to_return(
        status:,
        body: "{}"
      )
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.include(NotifyHelper)

    config.before do
      stub_any_post_sms_notification.to_return(sms_notification_api_response(:ok))
    end
  end
end
