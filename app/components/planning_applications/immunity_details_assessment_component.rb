# frozen_string_literal: true

module PlanningApplications
  class ImmunityDetailsAssessmentComponent < ViewComponent::Base
    def initialize(planning_application:, evidence_groups:)
      @planning_application = planning_application
      @evidence_groups = evidence_groups.map do |group|
        EvidenceGroupPresenter.new(view_context, group)
      end
    end

    delegate :immunity_detail, to: :planning_application

    attr_reader :planning_application, :evidence_groups
  end
end
