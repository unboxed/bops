# frozen_string_literal: true

class ReplacementDocumentValidationRequestsController < ValidationRequestsController
  include ValidationRequests

  before_action :ensure_planning_application_is_not_closed_or_cancelled, only: %i[new create]
  before_action :set_replacement_document_validation_request, only: %i[edit update]
  before_action :set_document, only: %i[new edit update]

  def new
    @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.new

    respond_to do |format|
      format.html
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def create
    @document = @planning_application.documents.find(document_id)

    ActiveRecord::Base.transaction do
      @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.new(replacement_document_validation_request_params).tap do |record|
        record.old_document = @document
        record.user = current_user
      end

      respond_to do |format|
        if @replacement_document_validation_request.save
          @document.replacement_document_validation_request = @replacement_document_validation_request

          format.html { redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success") }
        else
          format.html { render :new }
        end
      end
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to planning_application_validation_tasks_path(@planning_application), alert: "Could not find document with id: #{document_id}" }
    end
  end

  def update
    respond_to do |format|
      if @replacement_document_validation_request.update(replacement_document_validation_request_params)
        format.html { redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success") }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def set_document
    @document = if @replacement_document_validation_request
                  @replacement_document_validation_request.old_document
                else
                  @planning_application.documents.find(params[:document])
                end
  end

  def set_replacement_document_validation_request
    @replacement_document_validation_request = @planning_application.replacement_document_validation_requests.find(replacement_document_validation_request_id)
  end

  def replacement_document_validation_request_params
    params.require(:replacement_document_validation_request).permit(:reason)
  end

  def document_id
    Integer(params[:replacement_document_validation_request][:document_id])
  end

  def replacement_document_validation_request_id
    Integer(params[:id])
  end
end
