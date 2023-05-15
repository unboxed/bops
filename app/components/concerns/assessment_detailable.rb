# frozen_string_literal: true

module AssessmentDetailable
  extend ActiveSupport::Concern

  included do
    def assessment_details
      @assessment_details ||= planning_application.assessment_details_for_review
    end

    def assessment_details_updated?
      assessment_details.any? do |assessment_detail|
        assessment_detail_updated?(assessment_detail)
      end
    end

    def assessment_detail_updated?(assessment_detail)
      assessment_detail.review_required? &&
        rejected_assessment_detail_for_category?(assessment_detail.category)
    end

    def assessment_detail_update_required?(assessment_detail)
      planning_application.recommendation&.rejected? &&
        assessment_detail&.update_required?
    end

    def rejected_assessment_detail_for_category?(category)
      planning_application.rejected_assessment_detail(category:).present?
    end

    def review_assessment_details_complete?
      assessment_details.any? && assessment_details.all?(&:review_complete?)
    end
  end
end
