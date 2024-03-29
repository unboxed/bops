# frozen_string_literal: true

module BopsApi
  module V2
    class PlanningApplicationsController < AuthenticatedController
      skip_before_action :authenticate, only: :determined

      validate_schema! "submission", only: :create

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
        @planning_application = planning_applications_scope.find(planning_application_id)

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

      private

      def planning_application_id
        Integer(params[:id])
      rescue ArgumentError
        raise ActionController::BadRequest, "Invalid planning application id: #{params[:id].inspect}"
      end

      def send_email
        query_parameters[:send_email] == "true"
      end

      def creation_service
        @creation_service ||= Application::CreationService.new(
          local_authority: @local_authority,
          user: @current_user,
          params: request_parameters,
          send_email: send_email
        )
      end

      def query_service(scope = planning_applications_scope.by_created_at_desc)
        @query_service ||= Application::QueryService.new(scope, query_params)
      end

      def planning_applications_scope
        @local_authority.planning_applications.includes(:user)
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
