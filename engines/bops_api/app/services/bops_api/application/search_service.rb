# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      def initialize(scope, params)
        @scope = scope
        @params = params
        @query = params[:q]
      end

      attr_reader :scope, :params, :query

      def call
        Pagination.new(scope: search, params:).paginate
      end

      private

      def search
        return scope if query.blank?

        search_reference.presence || search_address.presence || search_description
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

      def search_postcode
        scope.where(
          "LOWER(replace(postcode, ' ', '')) = ?",
          query.gsub(/\s+/, "").downcase
        )
      end

      def search_address
        return search_address_results unless postcode_query?

        postcode_results = search_postcode
        postcode_results.presence || search_address_results
      end

      def search_address_results
        scope.where("address_search @@ to_tsquery('simple', ?)", query.split.join(" & "))
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

      def postcode_query?
        query.match?(/^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i)
      end
    end
  end
end
