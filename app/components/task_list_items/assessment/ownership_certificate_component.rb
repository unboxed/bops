# frozen_string_literal: true

module TaskListItems
  module Assessment
    class OwnershipCertificateComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
      end

      private

      attr_reader :planning_application

      delegate :ownership_certificate, to: :planning_application

      def link_text
        "Check ownership certificate"
      end

      def link_path
        if ownership_certificate.present? && ownership_certificate.current_review.status == "complete"
          planning_application_assessment_ownership_certificate_path(planning_application)
        else
          edit_planning_application_assessment_ownership_certificate_path(planning_application)
        end
      end

      def status_tag_component
        StatusTags::OwnershipCertificateComponent.new(planning_application:)
      end
    end
  end
end
