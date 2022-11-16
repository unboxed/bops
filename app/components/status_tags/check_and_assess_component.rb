# frozen_string_literal: true

module StatusTags
  class CheckAndAssessComponent < StatusTags::BaseComponent
    include AssessmentDetailable

    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate(:recommendation, to: :planning_application, allow_nil: true)

    def status
      if recommendation&.submitted_and_unchallenged?
        :complete
      elsif update_required?
        :to_be_reviewed
      elsif planning_application.assessment_tasklist_in_progress?
        :in_progress
      elsif planning_application.validated?
        :not_started
      end
    end

    def update_required?
      recommendation&.rejected? && assessment_details.any?(&:update_required?)
    end
  end
end
