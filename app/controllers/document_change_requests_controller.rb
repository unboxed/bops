class DocumentChangeRequestsController < ApplicationController
  def new
    @document_change_request = planning_application.document_change_requests.new
  end

  def create
    ActiveRecord::Base.transaction do
      planning_application.invalid_documents_without_change_request.each do |document|
        @document_change_request = planning_application.document_change_requests.new(old_document: document, user: current_user)
        @document_change_request.save!
      end
    end
    flash[:notice] = "Document change request successfully sent."
    send_change_request_email
    redirect_to planning_application_change_requests_path(@planning_application)
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
end
