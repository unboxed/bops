# frozen_string_literal: true

module Validation
  class CheckDescriptionTask < WorkflowTask
    def task_list_status
      if planning_application.valid_description?
        :complete
      elsif planning_application.description_change_validation_requests.open_or_pending.any?
        :invalid
      elsif planning_application.description_change_validation_requests.closed.any?
        :updated
      else
        :not_started
      end
    end

    def task_list_link_text
      if @planning_application.validated?
        "Planning application has already been validated"
      else
        I18n.t("task_list_items.description_change.check_description")

      end
    end

    def task_list_link
      return if @planning_application.validated?
      case task_list_status
      when :complete, :not_started
        planning_application_validation_description_changes_path(
          @planning_application
        )
      else
        planning_application_validation_description_change_validation_request_path(
          @planning_application,
          @planning_application.description_change_validation_requests.not_cancelled.last
        )
      end
    end
  end
end
