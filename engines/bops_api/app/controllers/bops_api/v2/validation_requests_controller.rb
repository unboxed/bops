# frozen_string_literal: true

module BopsApi
  module V2
    class ValidationRequestsController < AuthenticatedController
      def index
        @pagy, @validation_requests = query_service.call

        respond_to do |format|
          format.json
        end
      end

      private

      def query_service(scope = current_local_authority.validation_requests.notified.includes(:planning_application))
        @query_service ||= ValidationRequest::QueryService.new(scope, query_params)
      end

      def query_params
        params.permit(:page, :maxresults, :type, :from_date, :to_date)
      end
    end
  end
end
