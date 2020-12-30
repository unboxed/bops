# frozen_string_literal: true

class Api::V1::DocumentsController < Api::V1::ApplicationController
  skip_before_action :authenticate

  def show
    document = PlanningApplication.find(params[:planning_application_id]).documents.find(params[:id])
    redirect_to rails_blob_url(document.file)
  end
end
