# frozen_string_literal: true

module PlanningApplications
  class RowComponent < ViewComponent::Base
    def initialize(planning_application:, attributes:)
      @planning_application = PlanningApplicationPresenter.new(
        self,
        planning_application
      )

      @attributes = attributes
    end

    private

    attr_reader :planning_application, :attributes
  end
end
