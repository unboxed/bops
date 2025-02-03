# frozen_string_literal: true

module BopsApi
  module Comment
    class QueryService
      def initialize(scope, params)
        @scope = scope
        @params = params
        @query = params[:q]
      end

      attr_reader :scope, :params, :query

      def call
        Pagination.new(scope: apply_filtering(search), params: params).paginate
      end

      private

      def search
        return scope if query.blank?

        search_comment
      end

      def apply_filtering(scope)
        sort_by = params[:sort_by] || 'received_at'
        order = params[:order]

        scope.order("#{sort_by} #{order}")
      end

      def search_comment
        scope.select(sanitized_select_sql)
          .where(where_sql, query_terms)
          .order(rank: :desc)
      end

      def sanitized_select_sql
        ActiveRecord::Base.sanitize_sql_array([select_sql, query_terms])
      end

      def select_sql
        "neighbour_responses.*,
          neighbour_responses.redacted_response,
          ts_rank(
            to_tsvector('english', neighbour_responses.redacted_response),
            to_tsquery('english', ?)
        ) AS rank"
      end

      def where_sql
        "to_tsvector('english', neighbour_responses.redacted_response) @@ to_tsquery('english', ?)"
      end

      def query_terms
        @query_terms ||= query.split.join(" | ")
      end
    end
  end
end