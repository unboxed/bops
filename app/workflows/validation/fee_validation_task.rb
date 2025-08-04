# frozen_string_literal: true

module Validation
  class FeeValidationTask < WorkflowTask
    def task_list_link_text
      I18n.t("task_list_items.fee_component.check_fee")
    end

    def task_list_link
      return if planning_application.validated?

      case task_list_status
      when :complete, :not_started
        planning_application_validation_fee_items_path(
          planning_application
        )
      else
        planning_application_validation_fee_change_validation_request_path(
          planning_application,
          fee_change_validation_requests.not_cancelled.last
        )
      end
    end

    def task_list_status
      @task_list_status ||= if planning_application.valid_fee?
        :complete
      elsif fee_change_validation_requests.open_or_pending.any?
        :invalid
      elsif fee_change_validation_requests.closed.any?
        :updated
      else
        :not_started
      end
    end

    private

    delegate(:fee_change_validation_requests, to: :planning_application)
  end
end
