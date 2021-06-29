# frozen_string_literal: true

class Api::V1::AdditionalDocumentValidationRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update
  before_action :check_file_params_are_present, only: :update

  def update
    @additional_document_validation_request = @planning_application.additional_document_validation_requests.find_by(id: params[:id])
    new_document = @planning_application.documents.create!(file: params[:new_file])
    @additional_document_validation_request.update!(state: "closed", new_document: new_document)

    if @additional_document_validation_request.save

      audit("additional_document_validation_request_received", document_audit_item(new_document),
            @additional_document_validation_request.sequence)

      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request" }, status: :bad_request
    end
  end

private

  def check_file_params_are_present
    if params[:new_file].blank?
      render json: { "message": "A file must be selected to proceed." }, status: :bad_request
    end
  end

  def document_audit_item(document)
    document.name
  end
end
