# frozen_string_literal: true

require "notifications/client"

module TwoFactor
  class SmsNotification
    attr_reader :user, :mobile_number

    delegate :local_authority, to: :user
    delegate :current_otp, to: :user
    delegate :configuration, to: :Rails, prefix: :rails
    delegate :default_notify_api_key, to: :rails_configuration
    delegate :default_sms_template_id, to: :rails_configuration

    def initialize(user, mobile_number)
      @user = user
      @mobile_number = mobile_number
    end

    def deliver!
      client.send_sms(
        template_id: sms_template_id,
        phone_number: mobile_number,
        personalisation: {
          body: body
        }
      )
    end

    private

    def sms_template_id
      local_authority&.sms_template_id || default_sms_template_id
    end

    def notify_api_key
      local_authority&.notify_api_key || default_notify_api_key
    end

    def client
      @client ||= Notifications::Client.new(notify_api_key)
    end

    def body
      "#{current_otp} is your Back Office Planning System verification code."
    end
  end
end
