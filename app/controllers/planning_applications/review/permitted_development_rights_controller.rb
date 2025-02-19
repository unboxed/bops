# frozen_string_literal: true

module PlanningApplications
  module Review
    class PermittedDevelopmentRightsController < BaseController
      include PermittedDevelopmentRights

      before_action :set_permitted_development_right

      def update
        @permitted_development_right.reviewer = current_user
        @permitted_development_right.reviewed_at = Time.current

        respond_to do |format|
          format.html do
            if @permitted_development_right.update(permitted_development_right_params)
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-permitted-development-rights"),
                notice: I18n.t("permitted_development_rights.successfully_updated")
            else
              flash.now[:alert] = @permitted_development_right.errors.messages.values.flatten.join(", ")
              render_review_tasks
            end
          end
        end
      end

      private

      def permitted_development_right_params
        params.require(:permitted_development_right).permit(:accepted, :reviewer_comment, :review_status)
      end
    end
  end
end
