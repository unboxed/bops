# frozen_string_literal: true

module BopsSubmissions
  module V2
    class SubmissionsController < AuthenticatedController
      # FIxme to use the correct schema validation based on API user making the request.
      validate_schema! only: :create, if: :planx_submission?

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
          params: submission_params, headers: request.headers, local_authority: current_local_authority
        )
      end

      def submission_params
        planx_submission? ? request_parameters : planning_portal_params
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

      def planx_submission?
        params[:data].present?
      end
    end
  end
end
