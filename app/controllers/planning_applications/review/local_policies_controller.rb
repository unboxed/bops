# frozen_string_literal: true

module PlanningApplications
  module Review
    class LocalPoliciesController < BaseController
      before_action :set_local_policy, only: %i[show edit update]
      before_action :set_review_local_policy, only: %i[show edit update]

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
        if @review_local_policy.update(review_local_policy_params)
          redirect_to planning_application_review_tasks_path(@planning_application),
            notice: I18n.t("local_policies.successfully_updated")
        else
          render :edit
        end
      end

      private

      def review_local_policy_params
        params.require(:review)
          .permit(:comment, :action)
          .to_h
          .deep_merge(
            reviewed_at: Time.current,
            reviewer: current_user,
            review_status:,
            status: local_policy_status,
            id: @local_policy&.current_review&.id
          )
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end

      def set_local_policy
        @local_policy = @planning_application.local_policy
      end

      def set_review_local_policy
        @review_local_policy = @local_policy.current_review
      end

      def local_policy_status
        return_to_officer? ? :to_be_reviewed : :complete
      end

      def return_to_officer?
        params.dig(:review, :action) == "rejected"
      end

      def ensure_user_is_reviewer
        current_user.reviewer?
      end
    end
  end
end
