# frozen_string_literal: true

module BopsApi
  module V2
    module PlanningApplications
      class NeighbourResponsesController < AuthenticatedController
        before_action :set_planning_application

        def create
          unless @planning_application.application_type.consultation_steps.include? "neighbour"
            raise NeighbourResponseCreationService::CreateError, "This application type cannot accept neighbour responses"
          end

          @neighbour_response = NeighbourResponseCreationService.new(
            params:, planning_application: @planning_application
          ).call

          respond_to do |format|
            format.json
          end
        rescue NeighbourResponseCreationService::CreateError => e
          if e.message.start_with?("Validation failed:")
            raise ActionController::BadRequest.new(e.message)
          else
            raise
          end
        end

        private

        def required_api_key_scope = "comment"

        def set_planning_application
          @planning_application = find_planning_application params[:planning_application_id]
        end
      end
    end
  end
end
