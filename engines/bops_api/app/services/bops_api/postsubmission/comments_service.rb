# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsService
      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      def call
        result = filters.reduce(@scope) do |scope, filter|
          filter.applicable?(@params) ? filter.apply(scope, @params) : scope
        end
        result = sorter.call(result, @params)
        paginate(result)
      end

      private

      attr_reader :params

      def filters
        [
          Filters::Comments::QueryFilter.new,
          Filters::Comments::SentimentFilter.new(model_class)
        ]
      end

      def sorter
        Sorting::Sorter.new(allowed_fields: sort_fields)
      end

      def sort_fields
        {
          "received_at" => {default_order: "desc"},
          "id" => {column: "#{model_class.table_name}.id", default_order: "asc"}
        }
      end

      def model_class
        @scope.klass
      end

      def paginate(scope)
        PostsubmissionPagination.new(scope: scope, params: params).call
      end
    end
  end
end
