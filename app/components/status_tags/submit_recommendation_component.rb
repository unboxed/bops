# frozen_string_literal: true

module StatusTags
  class SubmitRecommendationComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    def status
      :complete if planning_application.submit_recommendation_complete?
    end
  end
end
