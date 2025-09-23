# frozen_string_literal: true

module BopsCore
  module Notify
    class SmsForm < BaseForm
      attribute :phone_number, :string
      attribute :body, :string

      validates :phone_number, :body, presence: true
      validates :phone_number, format: {with: /\A\+447[0-9]{9}\z/}

      delegate :sms_template_id, to: :local_authority

      def check
        super do
          @response = client.send_sms(
            phone_number: phone_number,
            template_id: sms_template_id,
            reference: reference,
            personalisation: {
              body: body
            }
          )
        end
      end
    end
  end
end
