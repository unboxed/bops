# frozen_string_literal: true

module BopsApplicants
  class ReplacementDocumentValidationRequestsController < ValidationRequestsController
    before_action :set_documents, only: %i[show]
    before_action :validate_replacement_document, only: %i[update]

    private

    def set_documents
      @old_document = @validation_request.old_document
      @new_document = @validation_request.new_document
    end

    def replacement_document_url
      if @validation_request.open?
        edit_replacement_document_validation_request_path(@validation_request.id, access_control_params)
      else
        replacement_document_validation_request_path(@validation_request.id, access_control_params)
      end
    end

    def validate_replacement_document
      return if replacement_file.blank?

      unless permitted_content_type?(replacement_file)
        redirect_to replacement_document_url, alert: "Only JPEG, PNG or PDF file types are supported" and return
      end
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
