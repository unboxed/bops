# frozen_string_literal: true

module Api
  module V1
    class PlanningApplicationsController < Api::V1::ApplicationController
      before_action :set_cors_headers, only: %i[index show create], if: :json_request?

      skip_before_action :authenticate, only: %i[index show decision_notice]
      skip_before_action :set_default_format, only: %i[decision_notice]

      def index
        @planning_applications = current_local_authority.planning_applications.all.includes([:user])

        respond_to(:json)
      end

      def show
        @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
        if @planning_application
          respond_to(:json)
        else
          send_not_found_response
        end
      end

      def decision_notice
        @planning_application = current_local_authority.planning_applications.where(id: params[:id]).first
        @blank_layout = true
      end

      def create
        @planning_application = PlanningApplicationCreationService.new(
          local_authority: current_local_authority, params:, api_user: current_api_user
        ).call

        send_success_response

        post_application_to_staging if Rails.configuration.production_environment
      rescue PlanningApplicationCreationService::CreateError => e
        send_failed_response(e, params)
      end

      private

      def send_success_response
        render json: { id: @planning_application.reference.to_s,
                       message: "Application created" }, status: :ok
      end

      def send_failed_response(error, params)
        Appsignal.send_error(error) do |transaction|
          transaction.params = { params: params.to_unsafe_hash }
        end

        render json: { message: error.message.to_s || "Unable to create application" },
               status: :bad_request
      end

      def send_not_found_response
        render json: { message: "Unable to find record" },
               status: :not_found
      end

      def post_application_to_staging
        PostApplicationToStagingJob.perform_later(current_local_authority, @planning_application)
      end
    end
  end
end
