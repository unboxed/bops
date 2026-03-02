# frozen_string_literal: true

module BopsApplicants
  class AdditionalDocumentValidationRequestsController < ValidationRequestsController
    before_action :set_documents, only: %i[show]
    before_action :validate_additional_documents, only: %i[update]

    private

    def set_documents
      @documents = @validation_request.additional_documents
    end

    def additional_documents_url
      if @validation_request.open?
        edit_additional_document_validation_request_path(@validation_request.id, access_control_params)
      else
        additional_document_validation_request_path(@validation_request.id, access_control_params)
      end
    end

    def validate_additional_documents
      uploaded_files.each do |file|
        unless permitted_content_type?(file)
          redirect_to additional_documents_url, alert: "Only JPEG, PNG or PDF file types are supported" and break
        end
      end
    end

    def validation_request_params
      params.require(:validation_request).permit(files: [])
    end

    def uploaded_files
      Array.wrap(validation_request_params[:files]).compact_blank
    end

    def update_validation_request
      transaction do
        @validation_request.upload_files!(uploaded_files)
        @planning_application.send_update_notification_to_assessor
      end

      true
    rescue
      false
    end
  end
end
