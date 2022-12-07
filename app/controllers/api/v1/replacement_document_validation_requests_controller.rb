# frozen_string_literal: true

module Api
  module V1
    class ReplacementDocumentValidationRequestsController < Api::V1::ValidationRequestsController
      skip_before_action :verify_authenticity_token

      before_action :check_token_and_set_application
      before_action :check_file_params_are_present,
                    :check_file_size,
                    :check_file_type, only: :update

      def index
        respond_to do |format|
          format.json do
            @replacement_document_validation_requests = @planning_application.replacement_document_validation_requests
          end
        end
      end

      def show
        respond_to do |format|
          if (@replacement_document_validation_request = @planning_application.replacement_document_validation_requests.where(id: params[:id]).first)
            format.json
          else
            format.json do
              render json: { message: "Unable to find replacement document validation request with id: #{params[:id]}" },
                     status: :not_found
            end
          end
        end
      end

      def update
        @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.find_by(id: params[:id])
        new_document = @planning_application.documents.create!(file: params[:new_file])
        @replacement_document_validation_request.update!(new_document: new_document)
        @replacement_document_validation_request.close!

        if @replacement_document_validation_request.save
          archive_old_document
          @replacement_document_validation_request.create_api_audit!
          @planning_application.send_update_notification_to_assessor
          render json: { message: "Validation request updated" }, status: :ok
        else
          render json: { message: "Unable to update request" }, status: :bad_request
        end
      end

      private

      def check_file_type
        return if Document::PERMITTED_CONTENT_TYPES.include? params[:new_file].content_type

        render json: { message: "The file type must be JPEG, PNG or PDF" }, status: :bad_request
      end

      def check_file_size
        return unless file_size_over_30mb?(params[:new_file])

        render json: { message: "The file must be 30MB or less" }, status: :bad_request
      end

      def check_file_params_are_present
        return if params[:new_file].present?

        render json: { message: "A file must be selected to proceed." }, status: :bad_request
      end

      def archive_old_document
        @replacement_document_validation_request.old_document.update!(
          archive_reason: "Applicant has provived a replacement document.",
          archived_at: Time.zone.now
        )
      end
    end
  end
end
