# frozen_string_literal: true

require "notifications/client"

module TwoFactor
  class SmsNotification
    NOTIFY_TEMPLATE_ID = "701e32b3-2c8c-4c16-9a1b-c883ef6aedee"

    attr_reader :mobile_number, :otp

    def initialize(mobile_number, otp)
      @mobile_number = mobile_number
      @otp = otp
    end

    def deliver!
      client.send_sms(
        template_id: NOTIFY_TEMPLATE_ID,
        phone_number: mobile_number,
        personalisation: {
          otp:
        }
      )
    end

    private

    def client
      @client ||= Notifications::Client.new(Rails.configuration.default_notify_api_key)
    end
  end
end
