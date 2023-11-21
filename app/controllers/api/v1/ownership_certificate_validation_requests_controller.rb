# frozen_string_literal: true

module Api
  module V1
    class OwnershipCertificateValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application

      def index
        respond_to do |format|
          format.json do
            @ownership_certificate_validation_requests = @planning_application.ownership_certificate_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          if (@ownership_certificate_validation_request =
                @planning_application.ownership_certificate_validation_requests.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: {message: "Unable to find ownership certificate validation request with id: #{params[:id]}"},
                status: :not_found
            end
          end
        end
      end

      def update
        @ownership_certificate_validation_request =
          @planning_application.ownership_certificate_validation_requests.where(id: params[:id]).first

        if @ownership_certificate_validation_request.update(ownership_certificate_params)
          @ownership_certificate_validation_request.close!
          @ownership_certificate_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor
          render json: {message: "Change request updated"}, status: :ok
        else
          render json: {message: "Unable to update request. Please ensure response is present"}, status: :bad_request
        end
      end

      def ownership_certificate_params
        {
          approved: params[:data][:approved],
          rejection_reason: params[:data][:rejection_reason]
        }
      end
    end
  end
end
