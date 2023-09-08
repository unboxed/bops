# frozen_string_literal: true

module Api
  module V1
    class NeighbourResponsesController < Api::V1::ApplicationController
      before_action :set_cors_headers, if: :json_request?
      before_action :set_application

      skip_before_action :authenticate

      def create
        @neighbour_response = NeighbourResponseCreationService.new(
          params:, planning_application: @planning_application
        ).call

        send_success_response
      rescue NeighbourResponseCreationService::CreateError => e
        send_failed_response(e)
      end

      def send_success_response
        render json: { id: @planning_application.reference.to_s,
                       message: "Response submitted" }, status: :ok
      end

      def send_failed_response(error)
        Appsignal.send_error(error)

        render json: { message: error.message.to_s || "Unable to create response" },
               status: :bad_request
      end

      private

      def set_application
        @planning_application =
          current_local_authority.planning_applications.find_by(id: params[:planning_application_id])

        return if @planning_application

        render json: { message: "Unable to find planning application with id: #{params[:planning_application_id]}" },
               status: :not_found
      end
    end
  end
end
