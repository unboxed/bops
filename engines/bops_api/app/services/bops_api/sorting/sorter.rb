# frozen_string_literal: true

module BopsApi
  module Sorting
    class Sorter
      ALLOWED_DIRECTIONS = %w[asc desc].freeze

      DEFAULT_FIELDS = {
        "published_at" => {default_order: "desc"},
        "received_at" => {default_order: "desc"}
      }.freeze

      def initialize(allowed_fields: DEFAULT_FIELDS, default_field: "received_at")
        @allowed_fields = allowed_fields
        @default_field = default_field
      end

      def call(scope, params)
        field_key = resolve_field(params)
        config = allowed_fields[field_key]
        column = Arel.sql(config[:column] || field_key)
        direction = resolve_direction(params, config)

        scope.reorder((direction == "desc") ? column.desc : column.asc)
      end

      private

      attr_reader :allowed_fields, :default_field

      def resolve_field(params)
        field = params[:sortBy].to_s.underscore
        allowed_fields.key?(field) ? field : default_field
      end

      def resolve_direction(params, config)
        return params[:orderBy] if ALLOWED_DIRECTIONS.include?(params[:orderBy])

        config[:default_order]
      end
    end
  end
end
