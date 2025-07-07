# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      ALLOWED_SORT_FIELDS = %w[publishedAt receivedAt].freeze
      DATE_FIELDS = %i[
        receivedAt
        validatedAt
        publishedAt
        consultationEndDate
      ].freeze

      def initialize(scope, params)
        @scope = scope
        @params = params
        @query = params[:q]
      end

      attr_reader :scope, :params, :query

      def call
        @scope = filter_by_application_type_code
        @scope = apply_date_filters
        @scope = search
        @scope = sort

        Pagination.new(scope: @scope, params:).paginate
      end

      private

      def sort
        field = params[:sortBy].presence_in(ALLOWED_SORT_FIELDS) || "receivedAt"
        direction = (params[:orderBy].to_s.downcase == "asc") ? :asc : :desc

        scope.reorder(field.underscore => direction)
      end

      def filter_by_application_type_code
        return @scope if params[:applicationType].blank?

        scope.for_application_type_codes(params[:applicationType])
      end

      def apply_date_filters
        DATE_FIELDS.reduce(scope) do |current, prefix|
          from_key = :"#{prefix}From"
          to_key = :"#{prefix}To"

          if params[from_key].present? || params[to_key].present?
            from = parse_date(params[from_key])&.beginning_of_day || Time.zone.at(0)
            to = parse_date(params[to_key])&.end_of_day || Time.zone.now.end_of_day

            scope_name = "#{prefix.to_s.underscore}_between"
            current.public_send(scope_name, from, to)
          else
            current
          end
        end
      end

      def parse_date(date_string)
        return if date_string.blank?
        Date.iso8601(date_string)
      rescue ArgumentError
        nil
      end

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
