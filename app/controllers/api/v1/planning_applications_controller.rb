# frozen_string_literal: true

module Api
  module V1
    class PlanningApplicationsController < Api::V1::ApplicationController
      before_action :set_cors_headers, only: %i[show], if: :json_request?

      skip_before_action :authenticate_api_user!, only: %i[decision_notice]
      skip_before_action :set_default_format, only: %i[decision_notice]

      def show
        @planning_application = planning_application
        if @planning_application
          respond_to(:json)
        else
          send_not_found_response
        end
      end

      def decision_notice
        @planning_application = planning_application
        @blank_layout = true
      end

      private

      def required_api_key_scope = "planning_application"

      def send_not_found_response
        render json: {message: "Unable to find record"},
          status: :not_found
      end
    end
  end
end
