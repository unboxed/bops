# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class EmailsController < AuthenticationController
      before_action :set_planning_application
      before_action :redirect_to_application_page, unless: :public_or_preapp?

      before_action :set_consultation
      before_action :set_consultees
      before_action :set_email_reason, only: %i[index]
      before_action :ensure_consultation_required

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
          :consultee_message_subject,
          :consultee_message_body,
          :consultee_response_period,
          :email_reason,
          :resend_message,
          :reconsult_message,
          {consultees_attributes: consultee_params}
        ]
      end

      def consultee_params
        %i[id selected]
      end

      def consultation_url
        planning_application_consultation_url(@planning_application)
      end

      def set_email_reason
        @consultation.email_reason = reason_param
      end

      def reason_param
        case params[:reason]
        when "reconsult"
          "reconsult"
        when "resend"
          "resend"
        else
          "send"
        end
      end

      def redirect_to_application_page
        redirect_to new_planning_application_publication_path(@planning_application), alert: t(".make_public")
      end

      def public_or_preapp?
        @planning_application.make_public? || @planning_application.pre_application?
      end

      def ensure_consultation_required
        return unless @planning_application.pre_application?
        return if @planning_application.consultation_required?

        redirect_to edit_planning_application_consultation_requirement_path(@planning_application),
          alert: t("planning_applications.consultation_requirements.required_before_tasks")
      end
    end
  end
end
