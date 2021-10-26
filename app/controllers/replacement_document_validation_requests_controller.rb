class ReplacementDocumentValidationRequestsController < ValidationRequestsController
  def new
    @replacement_document_validation_request = planning_application.replacement_document_validation_requests.new
  end

  def create
    ActiveRecord::Base.transaction do
      planning_application.invalid_documents_without_validation_request.each do |document|
        @replacement_document_validation_request = planning_application.replacement_document_validation_requests.new(old_document: document, user: current_user)
        @replacement_document_validation_request.save!
      end
    end

    flash[:notice] = "Replacement document validation request successfully created."
    email_and_timestamp(@replacement_document_validation_request) if @planning_application.invalidated?
    if @planning_application.invalidated?
      audit("replacement_document_validation_request_sent", document_change_audit_item(@replacement_document_validation_request),
            @replacement_document_validation_request.sequence)
    else
      audit("replacement_document_validation_request_added", document_change_audit_item(@replacement_document_validation_request),
            @replacement_document_validation_request.sequence)
    end
    redirect_to planning_application_validation_requests_path(@planning_application)
  end

private

  def planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def document_change_audit_item(replacement_document_validation_request)
    { old_document: replacement_document_validation_request.old_document.name,
      reason: replacement_document_validation_request.old_document.invalidated_document_reason }.to_json
  end
end
