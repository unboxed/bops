# frozen_string_literal: true

module ValidationRequests
  class CancellationsController < AuthenticationController
    include BopsCore::CancelsValidationRequests

    private

    def after_cancel_path
      task_path(@planning_application.reference, @task.full_slug)
    end

    def cancellation_form_url
      validation_request_cancellation_path(
        validation_request_id: @validation_request.id,
        task_slug: @task.full_slug
      )
    end
  end
end
