# frozen_string_literal: true

module TaskListItems
  class ValidationDecisionComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".send_validation_decision")
    end

    def link_path
      validation_decision_planning_application_path(planning_application)
    end

    def status
      if planning_application.validated?
        :valid
      elsif planning_application.invalidated?
        :invalid
      else
        :not_started
      end
    end
  end
end
