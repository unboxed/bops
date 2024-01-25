# frozen_string_literal: true

module PlanningApplications
  module Validation
    class ReportingTypesController < AuthenticationController
      before_action :set_planning_application

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        @planning_application.update!(reporting_type_params)

        respond_to do |format|
          format.html do
            if @planning_application.reporting_type.present?
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            elsif @planning_application.reporting_type.nil?
              flash.now[:alert] = t(".failure")
              render :edit
            end
          end
        end
      end

      private

      def reporting_type_params
        params[:planning_application] ? params.require(:planning_application).permit(:reporting_type) : params.permit(:reporting_type)
      end
    end
  end
end
