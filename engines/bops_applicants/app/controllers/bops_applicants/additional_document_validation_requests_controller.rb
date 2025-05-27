# frozen_string_literal: true

module BopsApplicants
  class AdditionalDocumentValidationRequestsController < ValidationRequestsController
    before_action :set_documents, only: %i[show]

    private

    def set_documents
      @documents = @validation_request.additional_documents
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
