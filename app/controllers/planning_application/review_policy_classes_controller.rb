# frozen_string_literal: true

class PlanningApplication
  class ReviewPolicyClassesController < AuthenticationController
    before_action :set_planning_application
    before_action :ensure_user_is_reviewer
    before_action :set_policy_class, only: %i[edit]

    def edit; end

    private

    def set_policy_class
      @policy_class = PolicyClassPresenter.new(
        @planning_application.policy_classes.find(params[:id])
      )
    end
  end
end
