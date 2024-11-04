# frozen_string_literal: true

module StatusTags
  class DecisionComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      planning_application.assessor_recommendation
    end
  end
end
