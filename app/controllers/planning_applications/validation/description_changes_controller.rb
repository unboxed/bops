# frozen_string_literal: true

module PlanningApplications
  module Validation
    class DescriptionChangesController < ValidationRequestsController
      before_action :ensure_planning_application_not_validated, only: %i[show validate]

      def show
        respond_to do |format|
          format.html
        end
      end

      def validate
        @planning_application.update!(description_changes_params)

        respond_to do |format|
          format.html do
            if @planning_application.valid_description?
              redirect_to planning_application_validation_tasks_path(@planning_application),
                notice: t(".success")
            elsif @planning_application.valid_description.nil?
              flash.now[:alert] = "Select Yes or No to continue."
              render :show
            else
              redirect_to new_planning_application_validation_validation_request_path(@planning_application, type: "description_change")
            end
          end
        end
      end

      private

      def description_changes_params
        params[:planning_application] ? params.require(:planning_application).permit(:valid_description) : params.permit(:valid_description)
      end
    end
  end
end
