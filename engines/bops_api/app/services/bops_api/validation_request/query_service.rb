# frozen_string_literal: true

module BopsApi
  module ValidationRequest
    class QueryService
      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        Pagination.new(scope: filter_by_type, params:).paginate
      end

      private

      def filter_by_type
        return scope if params[:type].blank?

        scope.where(type: params[:type])
      end
    end
  end
end
