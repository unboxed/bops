# frozen_string_literal: true

module Api
  module V1
    class DocumentsController < Api::V1::ApplicationController
      skip_before_action :authenticate_api_user!

      def show
        raise ActiveRecord::RecordNotFound unless planning_application
        document = planning_application.documents_for_publication.find(params[:id])
        redirect_to uploaded_file_url(document.blob), allow_other_host: true
      end

      def tags
        respond_to do |format|
          format.json do
            @tags = Document::TAGS
            @evidence_tags = Document::EVIDENCE_TAGS
            @drawing_tags = Document::DRAWING_TAGS
          end
        end
      end
    end
  end
end
