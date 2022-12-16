# frozen_string_literal: true

module ReviewTasks
  class AfterSignOffComponent < ViewComponent::Base
    def initialize(planning_application:)
      @planning_application = planning_application
      @recommendation = planning_application.recommendation
    end

    private

    def render?
      @planning_application.recommendation_review_complete? && challenged?
    end

    def challenged?
      @recommendation.challenged
    end

    def assessor_name
      @recommendation.assessor.name
    end
  end
end
