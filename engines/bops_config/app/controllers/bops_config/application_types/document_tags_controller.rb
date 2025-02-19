# frozen_string_literal: true

module BopsConfig
  module ApplicationTypes
    class DocumentTagsController < ApplicationController
      before_action :set_application_type
      before_action :set_document_tags

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @application_type.update(application_type_params, :document_tags)
            format.html do
              redirect_to next_path, notice: t(".success")
            end
          else
            format.html { render :edit }
          end
        end
      end

      private

      def application_type_params
        params.require(:application_type).permit(document_tags_attributes: document_tags_params)
      end

      def document_tags_params
        {drawings: [], evidence: [], supporting_documents: []}
      end

      def set_application_type
        @application_type = ApplicationType.find(application_type_id)
      end

      def set_document_tags
        @document_tags = @application_type.document_tags
      end

      def next_path
        if @application_type.configured?
          application_type_path(@application_type)
        else
          edit_application_type_decisions_path(@application_type)
        end
      end
    end
  end
end
