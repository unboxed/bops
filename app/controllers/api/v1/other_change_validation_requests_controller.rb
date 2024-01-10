# frozen_string_literal: true

module Api
  module V1
    class OtherChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_other_change_validation_request, only: %i[show update]

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      rescue_from ActiveRecord::RecordNotFound do
        render json: {message: "Unable to find other change validation request with id: #{params[:id]}"},
          status: :not_found
      end

      def index
        respond_to do |format|
          format.json do
            @other_change_validation_requests = @planning_application.other_change_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      end

      def update
        if params[:data][:response].present?
          ValidationRequestUpdateService.new(
            validation_request: @other_change_validation_request,
            params:
          ).call!
          render json: {message: "Change request updated"}, status: :ok
        else
          render json: {message: "Unable to update request. Please ensure response is present"}, status: :bad_request
        end
      end

      private

      def set_other_change_validation_request
        @other_change_validation_request = @planning_application.other_change_validation_requests.find(params[:id])
      end
    end
  end
end
