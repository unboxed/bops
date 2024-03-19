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
      if planning_application.in_committee?
        :not_started
      elsif (planning_application.recommendation_review_complete? && planning_application.committee_decision&.recommend?) || planning_application.to_be_reviewed?
        :complete
      end
    end
  end
end
