# frozen_string_literal: true

module Tasks
  class ReviewAndSubmitRecommendationForm < Form
    self.task_actions = %w[save_and_complete withdraw_recommendation]

    def flash(type, controller)
      result = case type
      when :notice
        "success"
      when :alert
        "failure"
      end

      if result == "failure" && open_post_validation_requests?
        controller.t(
          "planning_applications.recommendations.update.has_open_non_validation_requests_html",
          href: controller.post_validation_requests_planning_application_validation_validation_requests_path(planning_application)
        )
      else
        super
      end
    end

    private

    def save_and_complete
      return false if open_post_validation_requests?

      super do
        if planning_application.can_submit_recommendation?
          planning_application.submit_recommendation!
        end
      end
    rescue PlanningApplication::SubmitRecommendationError
      false
    end

    def open_post_validation_requests?
      !planning_application.no_open_post_validation_requests_excluding_time_extension?
    end

    def withdraw_recommendation
      transaction do
        planning_application.withdraw_last_recommendation!
        task.in_progress!
      end
    end
  end
end
