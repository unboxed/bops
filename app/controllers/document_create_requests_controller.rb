class DocumentCreateRequestsController < ApplicationController
  def new
    @document_create_request = planning_application.document_create_requests.new
  end

  def create
    @document_create_request = planning_application.document_create_requests.new(document_create_request_params)
    @document_create_request.user = current_user

    if @document_create_request.save
      flash[:notice] = "Document create request successfully sent."
      send_change_request_email
      audit("document_create_request_sent", document_create_audit_item(@document_create_request),
            @document_create_request.sequence)
      redirect_to planning_application_change_requests_path(@planning_application)
    else
      render :new
    end
  end

private

  def document_create_request_params
    params.require(:document_create_request).permit(:document_request_type, :document_request_reason)
  end

  def planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def send_change_request_email
    PlanningApplicationMailer.change_request_mail(
      @planning_application,
      @document_create_request,
    ).deliver_now
  end

  def document_create_audit_item(document_create_request)
    { document: document_create_request.document_request_type, reason: document_create_request.document_request_reason }.to_json
  end
end
