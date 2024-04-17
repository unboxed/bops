# frozen_string_literal: true

module StatusTags
  class AddCommitteeDecisionComponent < StatusTags::BaseComponent
    def initialize(planning_application:)
      @planning_application = planning_application
      super(status:)
    end

    private

    attr_reader :planning_application

    delegate :recommendation, to: :planning_application

    def status
      if (planning_application.awaiting_determination? || planning_application.to_be_reviewed?) && planning_application.committee_details_filled?
        :complete
      else
        :not_started
      end
    end
  end
end
