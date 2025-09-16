# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class PermittedDevelopmentRightsController < BaseController
      include PermittedDevelopmentRights

      rescue_from PermittedDevelopmentRight::NotCreatableError, with: :redirect_failed_create_error

      before_action :set_permitted_development_rights
      before_action :set_permitted_development_right
      before_action :ensure_planning_application_is_not_preapp

      def show
        respond_to do |format|
          format.html do
            if @permitted_development_right.complete? || @permitted_development_right.updated?
              render :show
            else
              redirect_to edit_planning_application_assessment_permitted_development_rights_path(@planning_application)
            end
          end
        end
      end

      def edit
        respond_to do |format|
          format.html do
            if @permitted_development_right.accepted?
              redirect_to planning_application_assessment_permitted_development_rights_path(@planning_application),
                alert: I18n.t("permitted_development_rights.already_accepted")
            else
              render :edit
            end
          end
        end
      end

      def update
        @permitted_development_right.assessor ||= current_user

        if current_user.reviewer?
          @permitted_development_right.reviewer ||= current_user
        end

        respond_to do |format|
          format.html do
            if @permitted_development_right.update_review(permitted_development_right_params)
              redirect_to redirect_path, notice: I18n.t("permitted_development_rights.successfully_updated")
            else
              render :edit
            end
          end
        end
      end

      private

      def permitted_development_right_params
        params.require(:permitted_development_right).permit(:removed, :removed_reason, :status)
      end

      def redirect_path
        if @planning_application.awaiting_determination?
          planning_application_review_tasks_path(@planning_application)
        else
          planning_application_assessment_tasks_path(@planning_application)
        end
      end

      def redirect_failed_create_error(error)
        redirect_to planning_application_assessment_tasks_path(@planning_application), alert: error.message
      end
    end
  end
end
