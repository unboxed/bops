# frozen_string_literal: true

module Api
  module V1
    class HeadsOfTermsValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_heads_of_terms_validation_request, only: %i[show update]

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: {message: "Unable to find heads of terms validation request with id: #{params[:id]}"},
          status: :not_found
      end

      def index
        respond_to do |format|
          format.json do
            @heads_of_terms_validation_requests = @planning_application.heads_of_terms_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      end

      def update
        ValidationRequestUpdateService.new(
          validation_request: @heads_of_terms_validation_request,
          params:
        ).call!

        render json: {message: "Change request updated"}, status: :ok
      end

      private

      def validation_request_id
        Integer(params[:id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid validation request id: #{params[:id].inspect}"
      end

      def set_heads_of_terms_validation_request
        @heads_of_terms_validation_request = @planning_application.heads_of_terms_validation_requests.find(validation_request_id)
      end
    end
  end
end
