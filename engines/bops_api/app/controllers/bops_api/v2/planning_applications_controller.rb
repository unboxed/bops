# frozen_string_literal: true

module BopsApi
  module V2
    class PlanningApplicationsController < AuthenticatedController
      validate_schema! "submission"

      def create
        @planning_application = creation_service.call!

        respond_to do |format|
          format.json
        end
      end

      private

      def send_email
        query_parameters[:send_email] == "true"
      end

      def creation_service
        @creation_service ||= Application::CreationService.new(
          local_authority: @local_authority,
          user: @current_user,
          params: request_parameters,
          send_email: send_email
        )
      end
    end
  end
end
