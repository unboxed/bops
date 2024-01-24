# frozen_string_literal: true

module PlanningApplications
  module Validation
    class EnvironmentImpactAssessmentsController < AuthenticationController
      before_action :set_planning_application
      before_action :set_environment_impact_assessment, only: %i[show update edit]

      def edit
        respond_to do |format|
          format.html
        end
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def new
        @environment_impact_assessment = @planning_application.build_environment_impact_assessment

        respond_to do |format|
          format.html
        end
      end

      def create
        @environment_impact_assessment = @planning_application.build_environment_impact_assessment

        respond_to do |format|
          if @environment_impact_assessment.update(environmental_impact_assessment_params)
            success_message = @environment_impact_assessment ? ".success_yes" : ".success_no"
            format.html { redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(success_message) }
          else
            format.html { render :edit }
          end
        end
      end

      def update
        respond_to do |format|
          if @environment_impact_assessment.update(environmental_impact_assessment_params)
            success_message = @planning_application.environment_impact_assessment.required? ? ".success_yes" : ".success_no"
            format.html { redirect_to planning_application_validation_tasks_path(@planning_application), notice: t(success_message) }
          else
            format.html { render :edit }
          end
        end
      end

      private

      def environmental_impact_assessment_params
        params.require(:environment_impact_assessment).permit(:required, :address, :email_address, :fee)
      end

      def set_environment_impact_assessment
        @environment_impact_assessment = @planning_application.environment_impact_assessment
      end
    end
  end
end
