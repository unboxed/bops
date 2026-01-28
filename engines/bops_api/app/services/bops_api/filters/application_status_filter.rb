# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationStatusFilter < BopsCore::Filters::StatusFilter
      def initialize
        super(param_key: :applicationStatus)
      end

      def applicable?(params)
        params.key?(param_key)
      end

      def apply(scope, params)
        statuses = normalized_values(params)
        return scope.none if statuses.empty?

        super
      end

      private

      def normalized_values(params)
        Array(params[param_key])
          .flat_map { |v| v.to_s.split(",") }
          .compact_blank
          .uniq
      end
    end
  end
end
