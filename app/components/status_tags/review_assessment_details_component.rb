# frozen_string_literal: true

module StatusTags
  class ReviewAssessmentDetailsComponent < StatusTags::BaseComponent
    include AssessmentDetailable
    include Recommendable

    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if updated?
        :updated
      elsif review_assessment_details_complete?
        :checked
      elsif assessment_details.any?(&:reviewer_verdict)
        :in_progress
      else
        :not_started
      end
    end

    def updated?
      recommendation_submitted_and_unchallenged? && assessment_details_updated?
    end
  end
end
