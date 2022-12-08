# frozen_string_literal: true

module StatusTags
  class PermittedDevelopmentRightReviewComponent < StatusTags::BaseComponent
    include PermittedDevelopmentRightable
    include Recommendable

    def initialize(planning_application:, permitted_development_right:)
      @planning_application = planning_application
      @permitted_development_right = permitted_development_right
    end

    private

    attr_reader :planning_application, :permitted_development_right

    def status
      if updated?
        :updated
      elsif permitted_development_right.review_complete?
        :complete
      elsif permitted_development_right.review_in_progress?
        :in_progress
      else
        :not_started
      end
    end

    def updated?
      recommendation_submitted_and_unchallenged? &&
        permitted_development_right_updated?
    end
  end
end
