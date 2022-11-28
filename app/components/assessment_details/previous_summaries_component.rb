# frozen_string_literal: true

module AssessmentDetails
  class PreviousSummariesComponent < ViewComponent::Base
    def initialize(planning_application:, category:)
      @planning_application = planning_application
      @category = category
    end

    private

    attr_reader :planning_application, :category

    def assessment_details
      planning_application.assessment_details.where(category: category)[1..]
    end
  end
end
