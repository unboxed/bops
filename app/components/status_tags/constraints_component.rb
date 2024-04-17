# frozen_string_literal: true

module StatusTags
  class ConstraintsComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      planning_application.constraints_checked? ? :checked : :not_started
    end
  end
end
