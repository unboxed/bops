# frozen_string_literal: true

module PlanningApplications
  class AssessmentReportComponent < ViewComponent::Base
    include FormatContentHelper

    def initialize(planning_application:, show_additional_evidence: false)
      @planning_application = planning_application
      @show_additional_evidence = show_additional_evidence
    end

    private

    attr_reader :planning_application, :show_additional_evidence

    delegate(
      :constraints,
      :past_applications,
      :summary_of_work,
      :site_description,
      :consultation_summary,
      :consultees,
      :policy_classes,
      :permitted_development_right,
      :additional_evidence,
      to: :planning_application
    )

    def documents
      planning_application.documents_for_decision_notice
    end
  end
end
