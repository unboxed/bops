# frozen_string_literal: true

module TaskListItems
  module Assessment
    class ValidationRequestComponent < TaskListItems::BaseComponent
      def initialize(planning_application:, request_type:)
        @planning_application = planning_application
        @request_type = request_type
      end

      private

      attr_reader :planning_application, :request_type

      def link_text
        "Send heads of terms"
      end

      def link_path
        if planning_application.validation_requests.where(type: request_type).any?
          planning_application_assessment_validation_request_path(@planning_application, validation_request)
        else
          new_planning_application_assessment_validation_request_path(@planning_application, type: "heads_of_terms")
        end
      end

      def status_tag_component
        StatusTags::BaseComponent.new(status:)
      end

      def status
        if validation_request.present?
          if validation_request.approved.nil?
            :in_progress
          else
            validation_request.approved? ? "valid" : "invalid"
          end
        else
          :not_started
        end
      end

      def validation_request
        planning_application.validation_requests.where(type: request_type).order(:created_at).last
      end
    end
  end
end
