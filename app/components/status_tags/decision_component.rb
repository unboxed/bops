# frozen_string_literal: true

module StatusTags
  class DecisionComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      planning_application.decision&.to_sym
    end

    def task_list?
      false
    end
  end
end
