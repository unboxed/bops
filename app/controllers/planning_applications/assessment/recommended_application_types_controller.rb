# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class RecommendedApplicationTypesController < BaseController
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
            if @planning_application.update(recommended_application_type_params, :recommended_application_type)
              redirect_to planning_application_assessment_tasks_path(@planning_application),
                notice: t(".success")
            else
              render :edit
            end
          end
        end
      end

      private

      def recommended_application_type_params
        params.require(:planning_application).permit(:recommended_application_type_id)
      end
    end
  end
end
