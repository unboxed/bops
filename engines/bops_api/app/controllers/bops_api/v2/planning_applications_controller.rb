# frozen_string_literal: true

module BopsApi
  module V2
    class PlanningApplicationsController < AuthenticatedController
      skip_before_action :authenticate_api_user!, only: :determined

      validate_schema! only: :create

      def index
        @pagy, @planning_applications = query_service.call

        respond_to do |format|
          format.json
        end
      end

      def determined
        # This endpoint is unauthenticated for public access
        @pagy, @planning_applications = query_service(
          determined_planning_applications_scope
        ).call

        respond_to do |format|
          format.json
        end
      end

      def show
        @planning_application = find_planning_application params[:id]

        respond_to do |format|
          format.json
        end
      end

      def create
        @planning_application = creation_service.call!

        respond_to do |format|
          format.json
        end
      end

      def submission
        @planning_application = find_planning_application params[:id]
        @submission = Application::SubmissionRedactionService.new(planning_application: @planning_application).call

        respond_to do |format|
          format.json
        end
      end

      def search
        @pagy, @planning_applications = search_service.call

        respond_to do |format|
          format.json
        end
      end

      private

      def required_api_key_scope = "planning_application"

      def send_email
        query_parameters[:send_email] == "true"
      end

      def creation_service
        @creation_service ||= Application::CreationService.new(
          local_authority: current_local_authority,
          user: current_api_user,
          params: request_parameters,
          email_sending_permitted: send_email
        )
      end

      def query_service(scope = planning_applications_scope.by_created_at_desc)
        @query_service ||= Application::QueryService.new(scope, query_params)
      end

      def determined_planning_applications_scope
        planning_applications_scope.determined.by_determined_at_desc
      end

      def query_params
        params.permit(:page, :maxresults, ids: [])
      end
    end
  end
end
