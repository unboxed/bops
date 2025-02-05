# frozen_string_literal: true

module BopsConsultees
  class DocumentsController < ApplicationController
    before_action :authenticate_with_sgid!, only: :show
    before_action :set_planning_application, only: %i[show]

    def show
      document = @planning_application.documents.find(params[:id])
      redirect_to main_app.uploaded_file_url(document.blob), allow_other_host: true
    end
  end
end
