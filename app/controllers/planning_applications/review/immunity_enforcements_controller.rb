# frozen_string_literal: true

module PlanningApplications
  module Review
    class ImmunityEnforcementsController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
      before_action :set_review_immunity_detail, only: %i[show edit update]

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
        @review_immunity_detail.assign_attributes(
          review_status: status, reviewer: current_user, reviewed_at: Time.current
        )

        respond_to do |format|
          if @review_immunity_detail.update(review_immunity_detail_params)
            format.html do
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: I18n.t("review_immunity_enforcements.successfully_updated")
            end
          else
            set_review_immunity_detail
            format.html { render :edit }
          end
        end
      end

      private

      def review_immunity_detail_params
        params.require(:review_immunity_detail).permit(:decision_reason, :accepted, :reviewer_comment)
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
