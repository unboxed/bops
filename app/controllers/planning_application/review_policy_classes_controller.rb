# frozen_string_literal: true

class PlanningApplication
  class ReviewPolicyClassesController < AuthenticationController
    include CommitMatchable
    before_action :set_planning_application
    before_action :ensure_user_is_reviewer
    before_action :set_policy_class, only: %i[edit update]

    def edit; end

    def update
      if @policy_class.update(policy_class_params)
        redirect_to(planning_application_review_tasks_path(@planning_application),
                    notice: t(".successfully_updated_policy_class"))
      else
        render :edit
      end
    end

    private

    def set_policy_class
      @policy_class = PolicyClassPresenter.new(
        @planning_application.policy_classes.find(params[:id])
      )
    end

    def policy_class_params
      params
        .require(:policy_class)
        .permit(policies_attributes: [:id, :status, :review_status, { comment_attributes: [:text] }])
        .merge(review_status: review_status)
    end

    def review_status
      mark_as_complete? ? :complete : :not_checked_yet
    end
  end
end
