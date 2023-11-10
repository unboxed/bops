# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class EmailsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation
      before_action :set_consultees

      def index
        respond_to do |format|
          format.html
        end
      end

      def create
        respond_to do |format|
          if @consultation.send_consultee_emails(permitted_params)
            format.html do
              redirect_to consultation_url, flash: {sent_consultee_emails: true}
            end
          else
            format.html { render :index }
          end
        end
      end

      private

      def set_consultees
        @consultees = @consultation.consultees
      end

      def permitted_params
        params.require(:consultation).permit(*consultation_params)
      end

      def consultation_params
        [
          :consultee_email_subject,
          :consultee_email_body,
          :email_reason,
          :resend_message,
          :reconsult_message,
          :reconsult_date,
          {consultees_attributes: consultee_params}
        ]
      end

      def consultee_params
        %i[id selected]
      end

      def consultation_url
        planning_application_consultation_url(@planning_application)
      end
    end
  end
end
