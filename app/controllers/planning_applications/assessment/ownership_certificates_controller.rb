# frozen_string_literal: true

module PlanningApplications
  module Assessment
    class OwnershipCertificatesController < ApplicationController
      include CommitMatchable

      before_action :set_planning_application
      before_action :set_valdiation_requests

      def edit
        respond_to do |format|
          format.html
        end
      end

      def show
        respond_to do |format|
          format.html
        end
      end

      def update
        if mark_as_complete?
          @planning_application.update!(valid_ownership_certificate: true)
          @planning_application.ownership_certificate&.update!(status:)
          redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success")
        else
          @planning_application.update!(valid_ownership_certificate: false)
          @planning_application.ownership_certificate&.update!(status:)
          redirect_to new_planning_application_validation_validation_request_path(@planning_application, type: "ownership_certificate")
        end
      end

      private

      def set_valdiation_requests
        @validation_requests = @planning_application.validation_requests.where(type: "OwnershipCertificateValidationRequest")
      end

      def status
        mark_as_complete? ? "complete" : "in_progress"
      end

      def valid_ownership_certificate
        mark_as_complete?
      end
    end
  end
end
