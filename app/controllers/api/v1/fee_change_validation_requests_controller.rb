# frozen_string_literal: true

module Api
  module V1
    class FeeChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application

      def index
        respond_to do |format|
          format.json do
            @fee_change_validation_requests = @planning_application.fee_change_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          if (@fee_change_validation_request =
                @planning_application.fee_change_validation_requests.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: {message: "Unable to find fee change validation request with id: #{params[:id]}"},
                status: :not_found
            end
          end
        end
      end

      def update
        @fee_change_validation_request =
          @planning_application.fee_change_validation_requests.where(id: params[:id]).first

        if params[:data][:response].present? &&
            @fee_change_validation_request.update(response: params[:data][:response])
          @fee_change_validation_request.close!
          @fee_change_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor
          render json: {message: "Change request updated"}, status: :ok
        else
          render json: {message: "Unable to update request. Please ensure response is present"}, status: :bad_request
        end
      end
    end
  end
end