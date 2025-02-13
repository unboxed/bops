# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class AssessmentReportComponent < ViewComponent::Base
      include AssessmentDetailHelper

      def initialize(planning_application:, show_additional_evidence: false, show_edit_links: true)
        @planning_application = planning_application
        @show_additional_evidence = show_additional_evidence
        @show_edit_links = show_edit_links
      end

      private

      attr_reader(
        :planning_application,
        :show_additional_evidence,
        :show_edit_links
      )

      delegate(
        :constraints,
        :site_histories,
        :summary_of_work,
        :site_description,
        :consultation_summary,
        :consultation,
        :permitted_development_right,
        :additional_evidence,
        :immunity_detail,
        :neighbour_summary,
        to: :planning_application
      )

      def considerations
        planning_application.consideration_set.considerations
      end

      def documents
        planning_application.documents_for_decision_notice
      end

      def current_user
        Current.user
      end
    end
  end
end
