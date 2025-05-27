# frozen_string_literal: true

module BopsApplicants
  class ReplacementDocumentValidationRequestsController < ValidationRequestsController
    before_action :set_documents, only: %i[show]

    private

    def set_documents
      @old_document = @validation_request.old_document
      @new_document = @validation_request.new_document
    end

    def validation_request_params
      params.require(:validation_request).permit(:replacement_file)
    end

    def replacement_file
      validation_request_params[:replacement_file]
    end

    def replacement_kwargs
      {file: replacement_file, reason: t(".applicant_has_provided")}
    end

    def update_validation_request
      transaction do
        @validation_request.replace_document!(**replacement_kwargs)
        @planning_application.send_update_notification_to_assessor
      end

      true
    rescue
      false
    end
  end
end
