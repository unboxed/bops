# frozen_string_literal: true

module PlanningApplication
  class ReviewPolicyAreasController < AuthenticationController
    include CommitMatchable
    include PlanningApplicationAssessable

    before_action :set_planning_application
    before_action :ensure_planning_application_is_validated
    before_action :ensure_user_is_reviewer
    before_action :set_policy_area, only: %i[show edit update]
    before_action :set_review_policy_area, only: %i[show edit update]

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
        if update_policy_areas
          format.html do
            redirect_to planning_application_review_tasks_path(@planning_application),
                        notice: I18n.t("policy_areas.successfully_updated")
          end
        else
          set_policy_area
          set_review_policy_area
          format.html { render :edit }
        end
      end
    end

    private

    def update_policy_areas
      ActiveRecord::Base.transaction do
        @review_policy_area.update(review_policy_area_params) &&
          @policy_area.update(considerations_params[:policy_area].merge(status: policy_area_status, review_status:))
      end
    end

    def review_policy_area_params
      params.require(:review_policy_area)
            .permit(:reviewer_comment, :accepted)
            .to_h
            .deep_merge(
              reviewed_at: Time.current,
              reviewer: current_user,
              review_status:,
              status: policy_area_status
            )
    end

    def review_status
      save_progress? ? "review_in_progress" : "review_complete"
    end

    def considerations_params
      params.require(:review_policy_area)
            .permit(policy_area:
              [considerations_attributes: %i[area policies guidance assessment id]])
    end

    def set_policy_area
      @policy_area = @planning_application.policy_area
    end

    def set_review_policy_area
      @review_policy_area = @policy_area.current_review_policy_area
    end

    def policy_area_status
      return_to_officer? ? :to_be_reviewed : :complete
    end

    def return_to_officer?
      params.dig(:review_policy_area, :accepted) == "false"
    end

    def ensure_user_is_reviewer
      current_user.reviewer?
    end
  end
end
