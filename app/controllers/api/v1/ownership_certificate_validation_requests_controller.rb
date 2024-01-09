# frozen_string_literal: true

module Api
  module V1
    class OwnershipCertificateValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_ownership_certificate_validation_requests, only: %i[index]
      before_action :set_ownership_certificate_validation_request, only: %i[show update]

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: {message: "Unable to find ownership certificate validation request with id: #{params[:id]}"},
          status: :not_found
      end

      def index
        respond_to do |format|
          format.json
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      end

      def update
        ValidationRequestUpdateService.new(
          validation_request: @ownership_certificate_validation_request,
          params:
        ).call!
        render json: {message: "Change request updated"}, status: :ok
      end

      private

      def set_ownership_certificate_validation_requests
        @ownership_certificate_validation_requests = @planning_application.ownership_certificate_validation_requests
      end

      def set_ownership_certificate_validation_request
        @ownership_certificate_validation_request =
          @planning_application.ownership_certificate_validation_requests.find(params[:id])
      end
    end
  end
end
