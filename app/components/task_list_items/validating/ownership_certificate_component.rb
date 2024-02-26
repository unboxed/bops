# frozen_string_literal: true

module TaskListItems
  module Validating
    class OwnershipCertificateComponent < TaskListItems::BaseComponent
      def initialize(planning_application:)
        @planning_application = planning_application
        @ownership_certificate = @planning_application.ownership_certificate
      end

      private

      attr_reader :planning_application, :ownership_certificate

      def link_text
        t(".link_text")
      end

      def link_path
        if @planning_application.valid_ownership_certificate.nil?
          edit_planning_application_validation_ownership_certificate_path(@planning_application)
        else
          planning_application_validation_ownership_certificate_path(@planning_application)
        end
      end

      def status_tag_component
        StatusTags::OwnershipCertificateComponent.new(
          planning_application:
        )
      end
    end
  end
end
