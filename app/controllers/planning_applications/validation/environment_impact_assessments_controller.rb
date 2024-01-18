# frozen_string_literal: true

module PlanningApplications
  module Validation
    class EnvironmentImpactAssessmentsController < AuthenticationController
      before_action :set_planning_application

      def edit
        respond_to do |format|
          format.html
        end
      end

      def update
        respond_to do |format|
          if @planning_application.update(environmental_impact_assessment_params)
            success_message = @planning_application.environment_impact_assessment ? ".success_yes" : ".success_no"
            format.html { redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(success_message) }
          else
            format.html { render :edit }
          end
        end
      end

      private

      def environmental_impact_assessment_params
        params.require(:planning_application).permit(:environment_impact_assessment)
      end
    end
  end
end
