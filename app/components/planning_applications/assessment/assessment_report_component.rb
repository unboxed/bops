# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class AssessmentReportComponent < ViewComponent::Base
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
        :consultation,
        :policy_classes,
        :permitted_development_right,
        :additional_evidence,
        :immunity_detail,
        to: :planning_application
      )

      def documents
        planning_application.documents_for_decision_notice
      end

      def local_policy_areas
        planning_application.local_policy.present? ? planning_application.local_policy.local_policy_areas : []
      end
    end
  end
end
