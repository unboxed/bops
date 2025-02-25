# frozen_string_literal: true

module BopsApi
  module V2
    class DocumentsController < AuthenticatedController
      def show
        @planning_application = find_planning_application params[:planning_application_id]
        @documents = @planning_application.documents.active
        @count = @documents.length

        respond_to do |format|
          format.json
        end
      end

      def download
        @planning_application = find_planning_application params[:planning_application_id]
        @document = @planning_application.documents.active.find(params[:document_id])
        redirect_to main_app.uploaded_file_url(@document.blob), allow_other_host: true
      end
    end
  end
end
