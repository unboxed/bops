# frozen_string_literal: true

module Api
  module V1
    class DocumentsController < Api::V1::ApplicationController
      skip_before_action :authenticate

      def show
        document =
          PlanningApplication.find(params[:planning_application_id]).documents.for_publication.find(params[:id])
        redirect_to rails_blob_url(document.file)
      end

      def tags
        respond_to do |format|
          format.json do
            @tags = Document::TAGS
            @evidence_tags = Document::EVIDENCE_TAGS
            @plan_tags = Document::PLAN_TAGS
          end
        end
      end
    end
  end
end
