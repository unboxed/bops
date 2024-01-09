# frozen_string_literal: true

module Api
  module V1
    class DescriptionChangeValidationRequestsController < Api::V1::ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_description_change_validation_request, only: %i[show update]

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      def index
        respond_to do |format|
          format.json do
            @description_change_validation_requests = @planning_application.description_change_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      rescue ActiveRecord::RecordNotFound
        format.json do
          render json: {message: "Unable to find description change validation request with id: #{params[:id]}"},
            status: :not_found
        end
      end

      def update
        ValidationRequestUpdateService.new(
          validation_request: @description_change_validation_request,
          params:,
          description_change: true
        ).call!

        render json: {message: "Change request updated"}, status: :ok
      end

      private

      def set_description_change_validation_request
        @description_change_validation_request = @planning_application.description_change_validation_requests.where(id: params[:id]).first
      end
    end
  end
end
