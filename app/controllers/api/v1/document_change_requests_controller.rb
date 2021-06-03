# frozen_string_literal: true

class Api::V1::DocumentChangeRequestsController < Api::V1::ApplicationController
  skip_before_action :verify_authenticity_token, only: :update
  before_action :check_token_and_set_application, only: :update
  before_action :check_file_params_are_present, only: :update

  def update
    @document_change_request = @planning_application.document_change_requests.find_by(id: params[:id])
    new_document = @planning_application.documents.create!(file: params[:new_file])
    @document_change_request.update!(state: "closed", new_document: new_document)

    if @document_change_request.save
      archive_old_document
      render json: { "message": "Change request updated" }, status: :ok
    else
      render json: { "message": "Unable to update request" }, status: 400
    end
  end

private

  def check_file_params_are_present
    if params[:new_file].blank?
      render json: { "message": "A file must be selected to proceed." }, status: 400
    end
  end

  def archive_old_document
    @document_change_request.old_document.update!(
      archive_reason: "Applicant has provived a replacement document.",
      archived_at: Time.zone.now,
    )
  end
end
