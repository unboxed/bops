# frozen_string_literal: true

module StatusTags
  class ReviewerAssessmentDetailComponent < StatusTags::BaseComponent
    def initialize(assessment_detail:)
      @assessment_detail = assessment_detail
    end

    private

    attr_reader :assessment_detail

    def status
      :updated if assessment_detail.updated?
    end

    def task_list?
      false
    end
  end
end
