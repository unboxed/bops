# frozen_string_literal: true

module BopsApi
  module V2
    module PlanningApplications
      class NeighbourResponsesController < AuthenticatedController
        def create
          @planning_application = find_planning_application(params[:planning_application_id])
          @consultation = @planning_application.consultation

          @neighbour_response = NeighbourResponse::NeighbourResponseCreationService.new(
            params:,
            planning_application: @planning_application
          ).call

          render json: {message: "Neighbour response created successfully"}, status: :created
        rescue NeighbourResponse::NeighbourResponseCreationService::CreateError => e
          render json: {error: e.message}, status: :unprocessable_entity
        end
      end
    end
  end
end
