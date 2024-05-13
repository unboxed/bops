# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      include Pagy::Backend

      DEFAULT_PAGE = 1
      DEFAULT_MAXRESULTS = 10
      MAXRESULTS_LIMIT = 20

      def initialize(scope, params)
        @scope = scope
        @params = params
        @query = params[:q]
      end

      attr_reader :scope, :params, :query

      def call
        paginate(search)
      end

      private

      def search
        return scope if query.blank?

        search_reference.presence || search_description
      end

      def search_reference
        scope.where(
          "LOWER(reference) LIKE ?",
          "%#{query.downcase}%"
        )
      end

      def search_description
        scope.select(sanitized_select_sql)
          .where(where_sql, query_terms)
          .order(rank: :desc)
      end

      def sanitized_select_sql
        ActiveRecord::Base.sanitize_sql_array([select_sql, query_terms])
      end

      def select_sql
        "planning_applications.*,
          ts_rank(
            to_tsvector('english', description),
            to_tsquery('english', ?)
          ) AS rank"
      end

      def where_sql
        "to_tsvector('english', description) @@ to_tsquery('english', ?)"
      end

      def query_terms
        @query_terms ||= query.split.join(" | ")
      end

      def paginate(scope)
        page = (params[:page] || DEFAULT_PAGE).to_i
        maxresults = [(params[:maxresults] || DEFAULT_MAXRESULTS).to_i, MAXRESULTS_LIMIT].min

        pagy(scope, page:, items: maxresults)
      end
    end
  end
end
