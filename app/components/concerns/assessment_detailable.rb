# frozen_string_literal: true

module AssessmentDetailable
  extend ActiveSupport::Concern

  included do
    def assessment_details
      @assessment_details ||= AssessmentDetailsReview::ASSESSMENT_DETAILS.map do |assessment_detail|
        planning_application.send(assessment_detail)
      end.compact
    end

    def assessment_details_review_complete?
      assessment_details.any? && assessment_details.all?(&:review_complete?)
    end
  end
end
