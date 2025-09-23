# frozen_string_literal: true

module BopsCore
  module Notify
    class EmailForm < BaseForm
      attribute :email_address, :string
      attribute :subject, :string
      attribute :body, :string

      validates :email_address, :subject, :body, presence: true
      validates :email_address, format: {with: URI::MailTo::EMAIL_REGEXP}

      delegate :email_template_id, to: :local_authority
      delegate :email_reply_to_id, to: :local_authority

      def check
        super do
          @response = client.send_email(
            email_address: email_address,
            template_id: email_template_id,
            email_reply_to_id: email_reply_to_id.presence,
            reference: reference,
            personalisation: {
              subject: subject,
              body: body
            }
          )
        end
      end
    end
  end
end
