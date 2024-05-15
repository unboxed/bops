# frozen_string_literal: true

module BopsApi
  module Application
    class QueryService
      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        Pagination.new(scope: filter_by_ids, params:).paginate
      end

      private

      def filter_by_ids
        return scope if params[:ids].blank?

        scope.where(id: params[:ids])
      end
    end
  end
end
