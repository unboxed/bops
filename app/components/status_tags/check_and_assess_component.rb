# frozen_string_literal: true

module StatusTags
  class CheckAndAssessComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    def status
      if planning_application.recommendation&.submitted_and_unchallenged?
        :complete
      elsif planning_application.assessment_tasklist_in_progress?
        :in_progress
      elsif planning_application.validated?
        :not_started
      end
    end
  end
end
