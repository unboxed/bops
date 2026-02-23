# frozen_string_literal: true

module PlanningApplications
  module Validation
    module Document
      class RedactionsController < AuthenticationController
        before_action :set_planning_application

        def index
          respond_to do |format|
            format.html
          end
        end

        def create
          filter_tags!
          @planning_application.assign_attributes(planning_application_params)

          respond_to do |format|
            format.html do
              if @planning_application.save
                redirect_to planning_application_validation_path(@planning_application), notice: t(".success")
              else
                render :index
              end
            end
          end
        end

        private

        def planning_application_params
          params.require(:planning_application)
            .permit(:documents_status, documents_attributes: documents_params)
        end

        def documents_params
          [:file, :redacted, :publishable, :validated, tags: []]
        end

        def filter_tags!
          return unless params[:planning_application][:documents_attributes]

          params[:planning_application][:documents_attributes].each do |index, document_attributes|
            if document_attributes[:tags].is_a?(String)
              params[:planning_application][:documents_attributes][index][:tags] = document_attributes[:tags].split
            end
          end
        end
      end
    end
  end
end
