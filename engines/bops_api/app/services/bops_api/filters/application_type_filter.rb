# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationTypeFilter < BopsCore::Filters::ApplicationTypeFilter
      def initialize
        super(param_key: :applicationType)
      end

      def applicable?(params)
        params.key?(param_key)
      end

      def apply(scope, params)
        codes = normalized_values(params)
        return scope.none if codes.empty?

        scope.for_application_type_codes(codes)
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
