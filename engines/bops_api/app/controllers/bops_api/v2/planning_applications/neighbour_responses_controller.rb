# frozen_string_literal: true

module BopsApi
    module V2
        module PlanningApplications
            class NeighbourResponsesController < AuthenticatedController
    def create
      @planning_application = find_planning_application(params[:planning_application_id])
      @consultation = @planning_application.consultation

      @neighbour_response = NeighbourResponseCreationService.new(
        params:,
        planning_application: @planning_application
      ).call

      render json: {message: "Neighbour response created successfully"}, status: :created
    rescue NeighbourResponseCreationService::CreateError => e
      render json: {error: e.message}, status: :unprocessable_entity
    end

              private

    def find_neighbour
        @consultation.neighbours.find_by(address: neighbour_response_params[:address])
    end

    def validate_required_params!(*required_keys)
      missing_keys = required_keys.select { |key| neighbour_response_params[key].blank? }
      if missing_keys.any?
        raise BopsApi::Errors::InvalidRequestError, "#{missing_keys.join(", ").humanize} #{"is".pluralize(missing_keys.size)} required"
      end
    end

    def neighbour_response_params
        params.permit(
          :name, :address, :response, :summary_tag, :tags, :email, tags: []
        )
    end

    def set_error_messages
      flash.now[:alert] = @neighbour_response.neighbour.errors.full_messages.join("\n") if @neighbour_response.neighbour&.errors&.any?
    end
            end
        end
    end
end
# end
