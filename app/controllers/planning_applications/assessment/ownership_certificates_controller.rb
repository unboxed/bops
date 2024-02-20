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
        ActiveRecord::Base.transaction do
          @planning_application.update!(valid_ownership_certificate:)
          @planning_application.ownership_certificate&.current_review&.update!(status:)
        end

        respond_to do |format|
          if @planning_application.valid_ownership_certificate
            format.html { redirect_to planning_application_assessment_tasks_path(@planning_application), notice: t(".success") }
          else
            format.html { redirect_to new_planning_application_validation_validation_request_path(@planning_application, type: "ownership_certificate") }
          end
        end
      rescue ActiveRecord::RecordInvalid
        set_error_messages

        render :edit
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

      def set_error_messages
        flash.now[:alert] = @planning_application.ownership_certificate.errors.full_messages.join("\n") if @planning_application&.ownership_certificate&.errors&.any?
      end
    end
  end
end
