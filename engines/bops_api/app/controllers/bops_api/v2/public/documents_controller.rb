# frozen_string_literal: true

module BopsApi
  module V2
    module Public
      class DocumentsController < PublicController
        def show
          @planning_application = find_planning_application params[:planning_application_id]
          @documents = @planning_application.documents_for_publication
          @count = @documents.length

          respond_to do |format|
            format.json
          end
        end

        def download
          @planning_application = find_planning_application params[:planning_application_id]
          @document = @planning_application.documents.active.for_publication.find(params[:document_id])
          redirect_to main_app.uploaded_file_url(@document.blob), allow_other_host: true
        end
      end
    end
  end
end
