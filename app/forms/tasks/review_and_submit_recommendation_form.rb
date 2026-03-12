# frozen_string_literal: true

module Tasks
  class ReviewAndSubmitRecommendationForm < Form
    self.task_actions = %w[save_and_complete withdraw_recommendation]

    def flash(type, controller)
      return nil unless type == :notice && after_success == "redirect"

      case action
      when "save_and_complete"
        controller.t(".review-and-submit-recommendation.success")
      when "withdraw_recommendation"
        controller.t(".review-and-submit-recommendation.withdraw_success")
      end
    end

    private

    def save_and_complete
      super do
        if planning_application.can_submit_recommendation?
          planning_application.submit_recommendation!
        end
      end
    end

    def withdraw_recommendation
      transaction do
        planning_application.withdraw_last_recommendation!
        task.in_progress!
      end
    end
  end
end
