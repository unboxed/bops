# frozen_string_literal: true

module BopsCore
  module Filters
    class StatusFilter
      def initialize(param_key: :status)
        @param_key = param_key
      end

      def applicable?(params)
        normalized_values(params).present?
      end

      def apply(scope, params)
        scope.where(status: normalized_values(params))
      end

      private

      attr_reader :param_key

      def normalized_values(params)
        Array(params[param_key]).compact_blank.uniq
      end
    end
  end
end
