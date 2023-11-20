# frozen_string_literal: true

module BopsApi
  module V2
    class PlanningApplicationsController < AuthenticatedController
      def create
        @planning_application = BopsApi::Application::CreationService.new(
          local_authority: @local_authority, params:, api_user: @current_user
        ).call

        send_success_response
      rescue BopsApi::Application::CreationService::CreateError => e
        send_failed_response(e, params)
      end

      private

      def send_success_response
        render json: {
          id: @planning_application.reference.to_s,
          message: "Application successfully created"
        }, status: :ok
      end

      def send_failed_response(error, params)
        Appsignal.send_error(error) do |transaction|
          transaction.params = {params: params.to_unsafe_hash}
        end

        json = {
          error: {
            code: 400,
            message: "Bad request",
            detail: error.message.to_s
          }
        }

        render json: json, status: :bad_request
      end
    end
  end
end
