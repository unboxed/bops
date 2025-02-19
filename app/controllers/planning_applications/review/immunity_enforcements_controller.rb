# frozen_string_literal: true

module PlanningApplications
  module Review
    class ImmunityEnforcementsController < BaseController
      before_action :set_review_immunity_detail, only: :update

      def update
        @review_immunity_detail.assign_attributes(
          review_status: status, reviewer: current_user, reviewed_at: Time.current
        )

        respond_to do |format|
          format.html do
            if @review_immunity_detail.update(review_immunity_detail_params)
              redirect_to planning_application_review_tasks_path(@planning_application, anchor: "review-immunity-enforcements"),
                notice: I18n.t("review_immunity_enforcements.successfully_updated")
            else
              flash.now[:alert] = @review_immunity_detail.errors.messages.values.flatten.join(", ")
              render_review_tasks
            end
          end
        end
      end

      private

      def review_immunity_detail_params
        params.require(:review_immunity_detail_enforcement).permit(:decision_reason, :action, :comment)
      end

      def set_review_immunity_detail
        @review_immunity_detail = @planning_application.immunity_detail.current_enforcement_review_immunity_detail
      end

      def status
        save_progress? ? "review_in_progress" : "review_complete"
      end
    end
  end
end
