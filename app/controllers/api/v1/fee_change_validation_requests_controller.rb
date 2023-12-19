# frozen_string_literal: true

module Api
  module V1
    class FeeChangeValidationRequestsController < Api::V1::ValidationRequestsController
      skip_before_action :verify_authenticity_token
      before_action :check_token_and_set_application
      before_action :check_files_size,
        :check_files_type, only: :update

      rescue_from ValidationRequest::UploadFilesError do |_exception|
        render_failed_request
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
        @fee_change_validation_request = @planning_application.fee_change_validation_requests.find_by(id: params[:id])

        if @fee_change_validation_request.update(fee_change_validation_request_params)
          @fee_change_validation_request.close!
          @fee_change_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor

          render json: {message: "Change request updated"}, status: :ok
        else
          render json: {message: "Unable to update request."}, status: :bad_request
        end
      end

      private

      def fee_change_validation_request_params
        params.permit(:response, supporting_documents: [])
      end

      def file_params
        params[:supporting_documents]
      end
    end
  end
end
