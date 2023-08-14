# frozen_string_literal: true

module TaskListItems
  class LegislationComponent < TaskListItems::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def link_text
      t(".check_legislation")
    end

    def link_path
      planning_application_legislation_path(planning_application)
    end

    def status
      if planning_application.legislation_checked?
        :checked
      else
        :not_started
      end
    end
  end
end
