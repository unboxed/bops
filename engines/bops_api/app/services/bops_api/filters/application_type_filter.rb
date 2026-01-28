# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationTypeFilter
      def applicable?(params)
        params[:applicationType].present?
      end

      def apply(scope, params)
        codes = normalized_values(params)
        return scope.none if codes.empty?

        scope.for_application_type_codes(codes)
      end

      private

      def normalized_values(params)
        Array(params[:applicationType])
          .flat_map { |code| code.to_s.split(",") }
          .compact_blank
          .uniq
      end
    end
  end
end
