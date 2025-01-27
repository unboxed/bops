# frozen_string_literal: true

module BopsConsultees
  class DocumentsController < ApplicationController
    before_action :authenticate_with_sgid!, only: :show
    before_action :set_planning_application, only: %i[show]

    def show
      document = @planning_application.documents.find(params[:id])
      redirect_to main_app.uploaded_file_url(document.blob), allow_other_host: true
    end

    private

    def set_planning_application
      @planning_application = planning_applications_scope.find_by!(reference:)
    rescue ActiveRecord::RecordNotFound
      render_not_found
    end

    def planning_applications_scope
      @current_local_authority.planning_applications.active
    end

    def reference
      params[:planning_application_reference]
    end
  end
end
