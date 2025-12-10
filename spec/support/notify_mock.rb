# frozen_string_literal: true

module NotifyMock
  URL = "https://api.notifications.service.gov.uk/v2/notifications/email"

  APPLICATION = Module.new do
    class << self
      def call(env)
        params = JSON.parse(env["rack.input"].read)

        message = Mail::Message.new
        subject = params.dig("personalisation", "subject")
        body = params.dig("personalisation", "body")

        notification_id = SecureRandom.uuid

        message.message_id = "#{notification_id}@bops.test"
        message.from = "mock@bops.test"
        message.to = params["email_address"]
        message.subject = subject
        message.body = body

        ActionMailer::Base.deliveries << message

        response = {
          id: notification_id,
          reference: params["reference"],
          content: {
            body: message.html_part,
            subject: message.subject,
            from_email: message.from
          },
          template: {
            id: params["template_id"],
            version: 1,
            uri: "/v2/templates/#{params["template_id"]}"
          },
          uri: "/notifications/#{notification_id}"
        }

        [200, {"Content-Type" => "application/json"}, [response.to_json]]
      end
    end
  end

  class << self
    def url
      URL
    end

    def app
      APPLICATION
    end
  end
end

if RSpec.respond_to?(:configure)
  RSpec.configure do |config|
    config.before(:each) do |example|
      unless example.metadata[:notify] == false
        stub_request(:post, NotifyMock.url).to_rack(NotifyMock.app)
      end
    end
  end
end
