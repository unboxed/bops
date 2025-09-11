# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class DevelopmentTypesController < BaseController
      before_action :ensure_planning_application_is_not_preapp
      before_action :destroy_policy_classes_if_no_section_55, only: :update

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
            if @planning_application.update(section_55_development_params, :require_section_55_development)
              redirect_to planning_application_assessment_tasks_path(@planning_application),
                notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def section_55_development_params
        params.fetch(:planning_application, {}).permit(:section_55_development)
      end

      def destroy_policy_classes_if_no_section_55
        if params.dig(:planning_application, :section_55_development) == "false"
          @planning_application.planning_application_policy_classes.destroy_all
        end
      end
    end
  end
end
