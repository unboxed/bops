# frozen_string_literal: true

class ReplacementDocumentValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  def new
    @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.new
  end

  def create
    ActiveRecord::Base.transaction do
      @planning_application.invalid_documents_without_validation_request.each do |document|
        @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.new(
          old_document: document, user: current_user
        )
        @replacement_document_validation_request.save!
      end
    end

    flash[:notice] = "Replacement document validation request successfully created."
    email_and_timestamp(@replacement_document_validation_request) if @planning_application.invalidated?
    @replacement_document_validation_request.audit!

    redirect_to planning_application_validation_requests_path(@planning_application)
  end
end
