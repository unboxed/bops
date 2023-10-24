# frozen_string_literal: true

module PlanningApplications
  module Review
    class LocalPoliciesController < AuthenticationController
      include CommitMatchable
      include PlanningApplicationAssessable

      before_action :set_planning_application
      before_action :ensure_planning_application_is_validated
      before_action :ensure_user_is_reviewer
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
        respond_to do |format|
          if update_local_policies
            format.html do
              redirect_to planning_application_review_tasks_path(@planning_application),
                notice: I18n.t("local_policies.successfully_updated")
            end
          else
            set_local_policy
            set_review_local_policy
            format.html { render :edit }
          end
        end
      end

      private

      def update_local_policies
        ActiveRecord::Base.transaction do
          @review_local_policy.update(review_local_policy_params) &&
            @local_policy.update(local_policy_areas_params[:local_policy].merge(status: local_policy_status,
              review_status:))
        end
      end

      def review_local_policy_params
        params.require(:review_local_policy)
          .permit(:reviewer_comment, :accepted)
          .to_h
          .deep_merge(
            reviewed_at: Time.current,
            reviewer: current_user,
            review_status:,
            status: local_policy_status
          )
      end

      def review_status
        save_progress? ? "review_in_progress" : "review_complete"
      end

      def local_policy_areas_params
        params.require(:review_local_policy)
          .permit(local_policy:
                [local_policy_areas_attributes: %i[area policies guidance assessment id]])
      end

      def set_local_policy
        @local_policy = @planning_application.local_policy
      end

      def set_review_local_policy
        @review_local_policy = @local_policy.current_review_local_policy
      end

      def local_policy_status
        return_to_officer? ? :to_be_reviewed : :complete
      end

      def return_to_officer?
        params.dig(:review_local_policy, :accepted) == "false"
      end

      def ensure_user_is_reviewer
        current_user.reviewer?
      end
    end
  end
end
