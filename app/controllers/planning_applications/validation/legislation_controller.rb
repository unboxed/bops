# frozen_string_literal: true

module PlanningApplications
  module Validation
    class LegislationController < BaseController
      before_action :redirect_to_validation_tasks, unless: :legislative_requirements_feature?
      before_action :ensure_legislation_is_defined

      def show
        respond_to do |format|
          format.html
        end
      end

      def update
        @planning_application.mark_legislation_as_checked!

        respond_to do |format|
          if @planning_application.legislation_checked?
            format.html do
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            end
          else
            format.html do
              redirect_failed_update
            end
          end
        end
      rescue ActiveRecord::ActiveRecordError
        redirect_failed_update
      end

      private

      def ensure_legislation_is_defined
        return if @planning_application.application_type.legislation

        render plain: "Not found", status: :not_found
      end

      def redirect_failed_update
        redirect_to planning_application_validation_tasks_path(@planning_application), alert: t(".alert")
      end

      def redirect_to_validation_tasks
        redirect_to planning_application_validation_tasks_path(@planning_application)
      end

      def legislative_requirements_feature?
        @planning_application.application_type.legislative_requirements?
      end
    end
  end
end
