# frozen_string_literal: true

module AssessmentDetails
  class PreviousSummaryComponent < ViewComponent::Base
    def initialize(assessment_details:, assessment_detail:)
      @assessment_details = assessment_details
      @assessment_detail = assessment_detail
    end

    private

    delegate(:comment, to: :assessment_detail)

    attr_reader :assessment_details, :assessment_detail

    def description
      action = assessment_detail == assessment_details.last ? :created : :updated
      key = ".user_#{action}_#{assessment_detail.category}"
      t(key, user: assessment_detail.user.name)
    end
  end
end
