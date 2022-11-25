# frozen_string_literal: true

module StatusTags
  class AssessmentDetailsReviewComponent < StatusTags::BaseComponent
    include AssessmentDetailable

    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if assessment_details.any?(&:updated?)
        :updated
      elsif assessment_details_review_complete?
        :checked
      elsif assessment_details.any?(&:reviewer_verdict)
        :in_progress
      else
        :not_started
      end
    end
  end
end
