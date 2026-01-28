# frozen_string_literal: true

module BopsCore
  module Filters
    class ApplicationTypeFilter
      def initialize(param_key: :application_type)
        @param_key = param_key
      end

      def applicable?(params)
        normalized_values(params).present?
      end

      def apply(scope, params)
        names = normalized_values(params)
        return scope if names.empty?

        filtered = scope.joins(:application_type).where(application_type: {name: names})
        filtered.exists? ? filtered : scope
      end

      private

      attr_reader :param_key

      def normalized_values(params)
        Array(params[param_key]).compact_blank.uniq
      end
    end
  end
end
