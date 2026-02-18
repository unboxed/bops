# frozen_string_literal: true

module BopsPreapps
  module Tasks
    class SendEmailsToConsulteesForm < Form
      class << self
        def model_name
          ActiveModel::Name.new(self, nil, "Consultation")
        end
      end

      attribute :consultee_message_subject, :string
      attribute :consultee_message_body, :string
      attribute :consultee_response_period, :integer
      attribute :email_reason, :string

      attr_accessor :consultees_attributes

      after_initialize do
        consultation

        self.consultee_message_subject = consultation.consultee_message_subject
        self.consultee_message_body = consultation.consultee_message_body
        self.consultee_response_period = consultation.consultee_response_period
        self.email_reason = consultation.email_reason
      end

      delegate :default_consultee_message_body, :default_consultee_message_subject, to: :consultation

      def consultation
        @consultation ||= planning_application.consultation || planning_application.create_consultation!
      end

      def consultees
        consultation.consultees
      end

      private

      def save_and_complete
        if consultation.send_consultee_emails(form_params(params))
          task.complete!
        else
          errors.merge!(consultation.errors)
          false
        end
      end

      def form_params(params)
        params.require(:consultation).permit(
          :consultee_message_subject,
          :consultee_message_body,
          :consultee_response_period,
          :email_reason,
          consultees_attributes: %i[id selected]
        )
      end
    end
  end
end
