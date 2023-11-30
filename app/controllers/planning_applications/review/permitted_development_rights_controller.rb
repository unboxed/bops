# frozen_string_literal: true

module PlanningApplications
  module Review
    class PermittedDevelopmentRightsController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable
      include PermittedDevelopmentRights

      before_action :ensure_planning_application_is_validated
      before_action :set_permitted_development_right, only: %i[show edit update]
      before_action :set_permitted_development_rights, only: %i[show edit]

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
        @permitted_development_right.assign_attributes(
          review_status: status, reviewer: current_user, reviewed_at: Time.current
        )

        respond_to do |format|
          if @permitted_development_right.update(permitted_development_right_params)
            format.html do
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: I18n.t("permitted_development_rights.successfully_updated")
            end
          else
            set_permitted_development_rights
            format.html { render :edit }
          end
        end
      end

      private

      def permitted_development_right_params
        params.require(:permitted_development_right).permit(:removed_reason, :accepted, :reviewer_comment)
      end

      def status
        save_progress? ? "review_in_progress" : "review_complete"
      end
    end
  end
end
