# frozen_string_literal: true

module Api
  module V1
    class NeighbourResponsesController < Api::V1::ApplicationController
      before_action :set_cors_headers, if: :json_request?
      before_action :set_application

      def create
        unless @planning_application.application_type.consultation_steps.include? "neighbour"
          raise NeighbourResponseCreationService::CreateError, "This application type cannot accept neighbour responses"
        end

        @neighbour_response = NeighbourResponseCreationService.new(
          params:, planning_application: @planning_application
        ).call

        send_success_response
      rescue NeighbourResponseCreationService::CreateError => e
        send_failed_response(e)
      end

      def send_success_response
        render json: {id: @planning_application.reference.to_s,
                      message: "Response submitted"}, status: :ok
      end

      def send_failed_response(error)
        Appsignal.report_error(error)

        render json: {message: error.message.to_s},
          status: :bad_request
      end

      private

      def required_api_key_scope = "comment"

      def set_application
        @planning_application = planning_application

        return if @planning_application

        render json: {
                 message:
                  "Unable to find planning application with id: #{params[:planning_application_id]}"
               },
          status: :not_found
      end
    end
  end
end
