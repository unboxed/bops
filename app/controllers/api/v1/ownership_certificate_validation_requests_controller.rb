# frozen_string_literal: true

module Api
  module V1
    class OwnershipCertificateValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_ownership_certificate_validation_requests, only: %i[index]
      before_action :set_ownership_certificate_validation_request, only: %i[show update]

      def index
        respond_to do |format|
          format.json
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      rescue ActiveRecord::RecordNotFound
        format.json do
          render json: {message: "Unable to find ownership certificate validation request with id: #{params[:id]}"},
            status: :not_found
        end
      end

      def update
        @ownership_certificate_validation_request.update!(ownership_certificate_params.except(:params))
        @ownership_certificate_validation_request.close!
        @ownership_certificate_validation_request.create_api_audit!
        @planning_application.send_update_notification_to_assessor
        @planning_application.update(valid_ownership_certificate: true)

        if @ownership_certificate_validation_request.approved?
          OwnershipCertificateCreationService.new(
            params: ownership_certificate_params[:params], planning_application: @planning_application
          ).call
        end

        render json: {message: "Change request updated"}, status: :ok
      rescue ActiveRecord::RecordInvalid, NoMethodError
        render json: {message: "Unable to update request. Please ensure response is present"}, status: :bad_request
      end

      private

      def set_ownership_certificate_validation_requests
        @ownership_certificate_validation_requests = @planning_application.ownership_certificate_validation_requests
      end

      def set_ownership_certificate_validation_request
        @ownership_certificate_validation_request =
          @planning_application.ownership_certificate_validation_requests.find(id: params[:id])
      end

      def ownership_certificate_params
        {
          approved: params[:data][:approved],
          rejection_reason: params[:data][:rejection_reason],
          params: params[:data][:params]
        }
      end
    end
  end
end
