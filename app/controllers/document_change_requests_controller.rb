class DocumentChangeRequestsController < ApplicationController
  def new
    @document_change_request = planning_application.document_change_requests.new
  end

  def create
    @current_local_authority = current_local_authority
    @document_change_request_errors = []
    planning_application.documents.invalidated.each do |document|
      @document_change_request = planning_application.document_change_requests.new(document: document, user: current_user) unless document_request_exists?(document)

      if !@document_change_request.nil? && @document_change_request.save
        send_change_request_email
        flash[:notice] = "Document change request successfully sent."
      else
        @document_change_request_errors << "A change request document had already been created for #{document.name}."
      end
    end
    byebug
    redirect_to validate_documents_form_planning_application_path(@planning_application)
  end

private

  def planning_application
    @planning_application = PlanningApplication.find(params[:planning_application_id])
  end

  def send_change_request_email
    PlanningApplicationMailer.change_request_mail(
      @planning_application,
      @document_change_request,
    ).deliver_now
  end

  # prevent duplicate description change requests being created the same document ?

  def document_request_exists?(document)
    planning_application.document_change_requests.where(document: document).any?
  end
end
