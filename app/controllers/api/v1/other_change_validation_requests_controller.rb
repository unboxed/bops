# frozen_string_literal: true

module Api
  module V1
    class OtherChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application

      def index
        respond_to do |format|
          format.json do
            @other_change_validation_requests = @planning_application.validation_requests.other_changes
          end
        end
      end

      def show
        respond_to do |format|
          if (@other_change_validation_request =
                @planning_application.validation_requests.other_changes.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: {message: "Unable to find other change validation request with id: #{params[:id]}"},
                status: :not_found
            end
          end
        end
      end

      def update
        @other_change_validation_request =
          @planning_application.validation_requests.other_changes.where(id: params[:id]).first

        if params[:data][:applicant_response].present? &&
            @other_change_validation_request.update(applicant_response: params[:data][:applicant_response])
          @other_change_validation_request.close!
          @other_change_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor
          render json: {message: "Change request updated"}, status: :ok
        else
          render json: {message: "Unable to update request. Please ensure response is present"}, status: :bad_request
        end
      end
    end
  end
end
