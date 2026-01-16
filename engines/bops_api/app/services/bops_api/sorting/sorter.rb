# frozen_string_literal: true

module BopsApi
  module Sorting
    class Sorter
      ALLOWED_FIELDS = {
        "publishedAt" => "published_at",
        "receivedAt" => "received_at"
      }.freeze

      ALLOWED_DIRECTIONS = %w[asc desc].freeze

      def initialize(default_field: "received_at", default_direction: "desc")
        @default_field = default_field
        @default_direction = default_direction
      end

      def call(scope, params)
        column = ALLOWED_FIELDS[params[:sortBy]] || @default_field
        direction = ALLOWED_DIRECTIONS.include?(params[:orderBy]) ? params[:orderBy] : @default_direction

        scope.reorder(column => direction)
      end
    end
  end
end
