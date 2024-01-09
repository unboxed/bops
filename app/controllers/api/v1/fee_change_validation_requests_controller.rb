# frozen_string_literal: true

module Api
  module V1
    class FeeChangeValidationRequestsController < Api::V1::ValidationRequestsController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :set_fee_change_validation_request, only: %i[show update]
      before_action :check_files_size,
        :check_files_type, only: :update

      rescue_from ValidationRequest::UploadFilesError do |_exception|
        render_failed_request
      end

      rescue_from ValidationRequestUpdateService::UpdateError do |error|
        render json: {message: error.message}, status: :bad_request
      end

      def index
        respond_to do |format|
          format.json do
            @fee_change_validation_requests = @planning_application.fee_change_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          format.json
        end
      rescue ActiveRecord::RecordNotFound
        format.json do
          render json: {message: "Unable to find fee change validation request with id: #{params[:id]}"},
            status: :not_found
        end
      end

      def update
        ValidationRequestUpdateService.new(
          validation_request: @fee_change_validation_request,
          params:
        ).call!
        render json: {message: "Change request updated"}, status: :ok
      end

      private

      def file_params
        params[:supporting_documents]
      end

      def set_fee_change_validation_request
        @fee_change_validation_request = @planning_application.fee_change_validation_requests.find_by(id: params[:id])
      end
    end
  end
end
