# frozen_string_literal: true

class AdditionalDocumentValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  before_action :set_additional_document_validation_request, only: %i[edit update]
  before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]
  before_action :ensure_planning_application_not_validated, only: %i[new create edit update]
  before_action :ensure_planning_application_not_invalidated, only: :edit

  def new
    @additional_document_validation_request = @planning_application.additional_document_validation_requests.new

    respond_to do |format|
      format.html
    end
  end

  def create
    @additional_document_validation_request = @planning_application.additional_document_validation_requests.new(additional_document_validation_request_params)
    @additional_document_validation_request.user = current_user

    respond_to do |format|
      if @additional_document_validation_request.save
        email_and_timestamp(@additional_document_validation_request) if @planning_application.invalidated?

        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application), notice: "Additional document request successfully created."
        end
      else
        format.html { render :new }
      end
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    respond_to do |format|
      if @additional_document_validation_request.update(additional_document_validation_request_params)
        format.html do
          redirect_to planning_application_validation_tasks_path(@planning_application), notice: "Additional document request successfully updated"
        end
      else
        format.html { render :edit }
      end
    end
  end

  private

  def additional_document_validation_request_params
    params.require(:additional_document_validation_request).permit(:document_request_type, :document_request_reason)
  end

  def set_additional_document_validation_request
    @additional_document_validation_request = @planning_application.additional_document_validation_requests.find(params[:id])
  end
end
