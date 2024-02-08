# frozen_string_literal: true

module PlanningApplications
  module Validation
    class DocumentsController < AuthenticationController
      before_action :set_planning_application

      def edit
        @documents = @planning_application.documents.active
        @additional_document_validation_requests = @planning_application
          .additional_document_validation_requests
          .pre_validation
          .open_or_pending

        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @planning_application.update(validate_documents_params)
            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: validate_documents_notice(@planning_application)
            end
          else
            format.html { render :validation_documents }
          end
        end
      end

      private

      def validate_documents_params
        params.require(:planning_application).permit(:documents_missing)
      end

      def validate_documents_notice(planning_application)
        if planning_application.documents_missing?
          "Documents required are marked as invalid"
        else
          "Documents required are marked as valid"
        end
      end
    end
  end
end
