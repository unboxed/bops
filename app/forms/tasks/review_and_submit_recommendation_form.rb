# frozen_string_literal: true

module Tasks
  class ReviewAndSubmitRecommendationForm < Form
    self.task_actions = %w[save_and_complete withdraw_recommendation]

    private

    def save_and_complete
      super do
        if planning_application.can_submit_recommendation?
          planning_application.submit_recommendation!
        end
      end
    rescue PlanningApplication::SubmitRecommendationError
      false
    end

    def withdraw_recommendation
      transaction do
        planning_application.withdraw_last_recommendation!
        task.in_progress!
      end
    end
  end
end
