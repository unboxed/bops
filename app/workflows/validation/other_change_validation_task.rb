# frozen_string_literal: true

module Validation
  class OtherChangeValidationTask < WorkflowTask
    def initialize(planning_application, request_id:, request_sequence:, request_status:, task_list: nil)
      @request_id = request_id
      @request_sequence = request_sequence
      @request_status = request_status

      super(planning_application, task_list:)
    end

    def task_list_link_text
      I18n.t("task_list_items.other_change_request_component.view_other_validation", number: request_sequence)
    end

    def task_list_link
      return if planning_application.validated?

      planning_application_validation_other_change_validation_request_path(
        planning_application,
        request_id
      )
    end

    def task_list_status
      if request_status == "open" || request_status == "pending"
        :invalid
      elsif request_status == "closed"
        :updated
      end
    end

    private

    attr_reader :request_id, :request_sequence, :request_status
  end
end
