# frozen_string_literal: true

module TaskListItems
  class ConditionsComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      "Add conditions"
    end

    def link_path
      planning_application_conditions_path(@planning_application)
    end

    def status_tag_component
      StatusTags::BaseComponent.new(status:)
    end

    def status
      planning_application.conditions.any? ? "complete" : "not_started"
    end
  end
end
