# frozen_string_literal: true

module BopsApi
  module Application
    class QueryService
      include Pagy::Backend

      DEFAULT_PAGE = 1
      DEFAULT_MAXRESULTS = 10
      MAXRESULTS_LIMIT = 20

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        paginate(filter_by_ids)
      end

      private

      def filter_by_ids
        return scope if params[:ids].blank?

        scope.where(id: params[:ids])
      end

      def paginate(scope)
        page = (params[:page] || DEFAULT_PAGE).to_i
        maxresults = [(params[:maxresults] || DEFAULT_MAXRESULTS).to_i, MAXRESULTS_LIMIT].min

        pagy(scope, page:, items: maxresults)
      end
    end
  end
end
