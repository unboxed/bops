# frozen_string_literal: true

module BopsCore
  module Filters
    class ApplicationTypeFilter < BaseFilter
      def initialize(param_key: :application_type)
        @param_key = param_key
      end

      def applicable?(params)
        normalized_values(params).present?
      end

      def apply(scope, params)
        type_ids = ApplicationType.where(name: normalized_values(params)).ids
        return scope if type_ids.empty?

        scope.where(application_type_id: type_ids)
      end

      private

      attr_reader :param_key

      def normalized_values(params)
        Array(params[param_key]).compact_blank.uniq
      end
    end
  end
end
