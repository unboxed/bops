# frozen_string_literal: true

module AccordionSections
  class BaseComponent < ViewComponent::Base
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application
  end
end
