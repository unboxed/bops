# frozen_string_literal: true

module BopsApi
  module V2
    class PlanningApplicationsController < AuthenticatedController
      def create
        @planning_application = creation_service.call!

        respond_to do |format|
          format.json
        end
      end

      private

      def creation_service
        @creation_service ||= Application::CreationService.new(
          local_authority: @local_authority, user: @current_user, params:
        )
      end
    end
  end
end
