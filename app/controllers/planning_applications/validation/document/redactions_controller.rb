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
          @planning_application.assign_attributes(planning_application_params)

          respond_to do |format|
            format.html do
              if @planning_application.save
                redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(".success")
              else
                render :index
              end
            end
          end
        end

        private

        def planning_application_params
          params.require(:planning_application)
            .permit({documents_attributes: documents_params})
        end

        def documents_params
          %i[file redacted publishable]
        end
      end
    end
  end
end
