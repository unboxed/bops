# frozen_string_literal: true

module PlanningApplications
  module Consultee
    class RedactResponsesController < AuthenticationController
      before_action :set_planning_application
      before_action :set_consultation
      before_action :set_consultee_response

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        @consultee_response.redacted_by = current_user

        respond_to do |format|
          if @consultee_response.update(redact_consultee_response_params)
            format.html do
              redirect_to planning_application_consultee_responses_path(@planning_application), notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def redact_consultee_response_params
        params.require(:consultee_response).permit(
          :response, :redacted_response
        )
      end

      def set_consultee_response
        @consultee_response = @consultation.consultee_responses.find(Integer(params[:id]))
      end
    end
  end
end
