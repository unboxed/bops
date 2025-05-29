# frozen_string_literal: true

module BopsApi
  module V2
    class NeighbourResponsesController < AuthenticatedController
      def index
        @pagy, @responses = Pagination.new(scope: response_scope, params: query_params).paginate

        respond_to do |format|
          format.json
        end
      end

      private

      def required_api_key_scope = "comment"

      def response_scope
        current_local_authority.neighbour_responses
      end

      def query_params
        params.permit(:page, :maxresults)
      end
    end
  end
end
