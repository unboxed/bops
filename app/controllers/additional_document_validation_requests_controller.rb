# frozen_string_literal: true

class AdditionalDocumentValidationRequestsController < ValidationRequestsController
  def new
    @additional_document_validation_request = planning_application.additional_document_validation_requests.new
  end

  def create
    @additional_document_validation_request = planning_application.additional_document_validation_requests.new(additional_document_validation_request_params)
    @additional_document_validation_request.user = current_user

    if @additional_document_validation_request.save
      flash[:notice] = "Additional document request successfully created."
      email_and_timestamp(@additional_document_validation_request) if @planning_application.invalidated?
      if @planning_application.invalidated?
        audit("additional_document_validation_request_sent", document_create_audit_item(@additional_document_validation_request),
              @additional_document_validation_request.sequence)
      else
        audit("additional_document_validation_request_added", document_create_audit_item(@additional_document_validation_request),
              @additional_document_validation_request.sequence)
      end
      redirect_to planning_application_validation_requests_path(@planning_application)
    else
      render :new
    end
  end

  private

  def additional_document_validation_request_params
    params.require(:additional_document_validation_request).permit(:document_request_type, :document_request_reason)
  end

  def planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def document_create_audit_item(additional_document_validation_request)
    { document: additional_document_validation_request.document_request_type,
      reason: additional_document_validation_request.document_request_reason }.to_json
  end
end
