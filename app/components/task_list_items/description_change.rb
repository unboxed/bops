# frozen_string_literal: true

module TaskListItems
  class DescriptionChange < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:description_change_validation_requests, to: :planning_application)

    def link_text
      t(".check_description")
    end

    def link_path
      case status
      when :valid, :not_started
        planning_application_validation_description_changes_path(
          planning_application
        )
      else
        planning_application_validation_description_change_validation_request_path(
          planning_application,
          description_change_validation_requests.not_cancelled.last
        )
      end
    end

    def status
      @status ||= if planning_application.valid_description?
        :valid
      elsif description_change_validation_requests.open_or_pending.any?
        :invalid
      elsif description_change_validation_requests.closed.any?
        :updated
      else
        :not_started
      end
    end
  end
end
