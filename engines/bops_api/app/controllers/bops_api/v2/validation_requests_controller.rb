# frozen_string_literal: true

module BopsApi
  module V2
    class ValidationRequestsController < AuthenticatedController
      def index
        @planning_application = find_planning_application(params[:planning_application_id])
        @pagy, @validation_requests = query_service.call

        respond_to do |format|
          format.json
        end
      end

      private

      def planning_applications_scope
        @local_authority.planning_applications.includes(:user)
      end

      def query_service(scope = @planning_application.validation_requests)
        @query_service ||= ValidationRequest::QueryService.new(scope, query_params)
      end

      def query_params
        params.permit(:type)
      end
    end
  end
end