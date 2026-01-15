# frozen_string_literal: true

module BopsApi
  module Filters
    class ApplicationTypeFilter < BaseFilter
      def applicable?(params)
        params[:applicationType].present?
      end

      def apply(scope, params)
        scope.for_application_type_codes(normalized_codes(params))
      end

      private

      def normalized_codes(params)
        Array(params[:applicationType])
          .flat_map { |code| code.to_s.split(",") }
          .compact_blank
          .uniq
      end
    end
  end
end
