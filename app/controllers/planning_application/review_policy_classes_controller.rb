# frozen_string_literal: true

class PlanningApplication
  class ReviewPolicyClassesController < AuthenticationController
    include CommitMatchable
    before_action :set_planning_application
    before_action :ensure_user_is_reviewer
    before_action :set_policy_class, only: %i[edit update]

    def edit
      @policy_class.build_review_policy_class if @policy_class.review_policy_class.nil?
    end

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
      # params.require(:policy_class).permit!
      params
        .require(:policy_class)
        .permit(policies_attributes: [:id, :status, { comment_attributes: [:text] }],
                review_policy_class_attributes: {:id, :mark, :status}
        # I want review_status added into the review_policy_class_attributes
      end



    def review_status
      mark_as_complete? ? :complete : :not_checked_yet
    end
  end
end
