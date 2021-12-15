# frozen_string_literal: true

module Api
  module V1
    class AdditionalDocumentValidationRequestsController < Api::V1::ValidationRequestsController
      skip_before_action :verify_authenticity_token

      before_action :check_token_and_set_application
      before_action :check_files_params_are_present,
                    :check_files_size,
                    :check_files_type,
                    :current_api_user, only: :update

      rescue_from AdditionalDocumentValidationRequest::UploadFilesError do |_exception|
        render_failed_request
      end

      def index
        respond_to do |format|
          format.json do
            @additional_document_validation_requests = @planning_application.additional_document_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          if (@additional_document_validation_request = @planning_application.additional_document_validation_requests.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: { message: "Unable to find additional document validation request with id: #{params[:id]}" }, status: :not_found
            end
          end
        end
      end

      def update
        @additional_document_validation_request = @planning_application.additional_document_validation_requests.find_by(id: params[:id])

        if @additional_document_validation_request.can_upload?
          @additional_document_validation_request.upload_files!(params[:files])

          render json: { message: "Validation request updated" }, status: :ok
        else
          render_failed_request
        end
      end

      private

      def check_files_params_are_present
        if params[:files].empty?
          render json: { message: "At least one file must be selected to proceed." }, status: :bad_request
        end
      end

      def check_files_size
        if params[:files].map(&:size).sum > 30.megabytes
          render json: { message: "The total file size must be 30MB or less" }, status: :bad_request
        end
      end

      def check_files_type
        if params[:files].any? { |file| Document::PERMITTED_CONTENT_TYPES.exclude? file.content_type }
          render json: { message: "The file type must be JPEG, PNG or PDF" }, status: :bad_request
        end
      end
    end
  end
end
