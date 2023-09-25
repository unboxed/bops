# frozen_string_literal: true

class PlanningApplication
  class ReviewPolicyGuidancesController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :ensure_user_is_reviewer
    before_action :set_policy_guidance, only: %i[show edit update]
    before_action :set_review_policy_guidance, only: %i[show edit update]

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
        if update_policy_guidances
          format.html do
            redirect_to planning_application_review_tasks_path(@planning_application),
                        notice: I18n.t("policy_guidances.successfully_updated")
          end
        else
          set_policy_guidance
          set_review_policy_guidance
          format.html { render :edit }
        end
      end
    end

    private

    def update_policy_guidances
      ActiveRecord::Base.transaction do
        @review_policy_guidance.update(review_policy_guidance_params) &&
          @policy_guidance.update(status: policy_guidance_status, review_status:, assessment:)
      end
    end

    def review_policy_guidance_params
      params.require(:review_policy_guidance)
            .permit(:reviewer_comment, :accepted)
            .to_h
            .deep_merge(
              reviewed_at: Time.current,
              reviewer: current_user,
              review_status:,
              status: policy_guidance_status
            )
    end

    def review_status
      save_progress? ? "review_in_progress" : "review_complete"
    end

    def assessment
      params.require(:review_policy_guidance)
            .permit(:assessment)[:assessment]
    end

    def set_policy_guidance
      @policy_guidance = @planning_application.policy_guidance
    end

    def set_review_policy_guidance
      @review_policy_guidance = @policy_guidance.current_review_policy_guidance
    end

    def policy_guidance_status
      return_to_officer? ? :to_be_reviewed : :complete
    end

    def return_to_officer?
      params.dig(:review_policy_guidance, :accepted) == "false"
    end

    def ensure_user_is_reviewer
      current_user.reviewer?
    end
  end
end
