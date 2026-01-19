# frozen_string_literal: true

module BopsApi
  module Sorting
    class CommentsSorter
      ALLOWED_DIRECTIONS = %w[asc desc].freeze

      def initialize(allowed_fields:, default_field: "receivedAt")
        @allowed_fields = allowed_fields
        @default_field = default_field
      end

      def call(scope, params)
        sort_by = resolve_sort_by(params)
        order_by = resolve_order_by(params, sort_by)
        column = Arel.sql(allowed_fields[sort_by][:column])

        scope.reorder((order_by == "desc") ? column.desc : column.asc)
      end

      private

      attr_reader :allowed_fields, :default_field

      def resolve_sort_by(params)
        sort_by = params[:sortBy].to_s.camelize(:lower)
        allowed_fields.key?(sort_by) ? sort_by : default_field
      end

      def resolve_order_by(params, sort_by)
        ALLOWED_DIRECTIONS.include?(params[:orderBy]) ? params[:orderBy] : allowed_fields[sort_by][:default_order]
      end
    end
  end
end
