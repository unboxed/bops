# frozen_string_literal: true

module StatusTags
  class AddCommitteeDecisionComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
    end

    private

    attr_reader :planning_application

    delegate :recommendation, to: :planning_application

    def status
      if (planning_application.awaiting_determination? || planning_application.to_be_reviewed?) && planning_application.committee_decision.recommend? && planning_application.committee_decision.location.present?
        :complete
      else
        :not_started
      end
    end
  end
end
