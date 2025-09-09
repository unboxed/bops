# frozen_string_literal: true

module BopsSubmissions
  module V2
    class SubmissionsController < AuthenticatedController
      # TODO schema validation should be done only after submission, in the processor jobs
      validate_schema! only: :create, if: :odp_submission?

      def create
        @submission = creation_service.call
        SubmissionProcessorJob.perform_later(@submission.id, @current_api_user)

        respond_to do |format|
          format.json
        end
      end

      private

      def creation_service
        @creation_service ||= BopsSubmissions::CreationService.new(
          params: submission_params,
          headers: request.headers,
          local_authority: current_local_authority,
          schema:
        )
      end

      def submission_params
        odp_submission? ? request_parameters : planning_portal_params
      end

      def planning_portal_params
        params.permit(
          :applicationRef,
          :applicationVersion,
          :applicationState,
          :sentDateTime,
          :updated,
          documentLinks: [:documentName, :documentLink, :expiryDateTime, :documentType]
        ).to_h
      end

      def schema
        params[:schema] || "odp"
      end

      def odp_submission?
        schema == "odp"
      end
    end
  end
end
