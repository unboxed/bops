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

    {status:, body:}
  end

  def stub_send_letter(status:)
    body = {status_code: status}
    body[:errors] = [{error: "Exception", message: "Internal server error"}] if status >= 400

    stub_request(:post, LETTER_URL)
      .with do |request|
      body = JSON.parse(request.body, symbolize_names: true)
      body[:template_id] == local_authority.letter_template_id &&
        body[:personalisation][:address_line_1] == "The Occupier"
    end
      .to_return(
        status:,
        body: body.merge(id: "123").to_json
      )
  end

  def stub_get_notify_status(notify_id:)
    stub_request(:get, "https://api.notifications.service.gov.uk/v2/notifications/#{notify_id}")
      .to_return(status: 200, body: '{"status": "received", "created_at": "2023-06-01 13:56:46.195155325 +0100"}', headers: {})
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
