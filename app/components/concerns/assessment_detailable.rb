# frozen_string_literal: true

module AssessmentDetailable
  extend ActiveSupport::Concern

  included do
    delegate(:recommendation, to: :planning_application)

    def assessment_details
      @assessment_details ||= planning_application.assessment_details_for_review
    end

    def assessment_details_updated?
      return false unless recommendation_submitted_and_unchallenged?

      assessment_details.any? do |assessment_detail|
        assessment_detail_updated?(assessment_detail)
      end
    end

    def assessment_detail_updated?(assessment_detail)
      assessment_detail.review_required? &&
        rejected_assessment_detail_for_category?(assessment_detail.category)
    end

    def assessment_detail_update_required?(assessment_detail)
      recommendation&.rejected? && assessment_detail&.update_required?
    end

    def rejected_assessment_detail_for_category?(category)
      planning_application.rejected_assessment_detail(category: category).present?
    end

    def recommendation_submitted_and_unchallenged?
      recommendation&.submitted_and_unchallenged?
    end

    def assessment_details_review_complete?
      assessment_details.any? && assessment_details.all?(&:review_complete?)
    end
  end
end
