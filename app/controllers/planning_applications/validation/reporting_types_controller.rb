# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ReportingTypesController < BaseController
      def show
        respond_to do |format|
          format.html
        end
      end

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          format.html do
            if @planning_application.update(reporting_type_params, :reporting_types)
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def reporting_type_params
        (params[:planning_application] ? params.require(:planning_application) : params)
          .permit(:reporting_type_code, :regulation).to_h.merge(regulation_3:, regulation_4:)
      end

      def regulation_3
        regulation_params == "true" && regulation_3_params == "true"
      end

      def regulation_4
        regulation_params == "true" && regulation_3_params == "false"
      end

      def regulation_params
        params[:planning_application][:regulation]
      end

      def regulation_3_params
        params[:planning_application][:regulation_3]
      end
    end
  end
end
