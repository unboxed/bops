# frozen_string_literal: true

module BopsApi
  module Application
    class SearchService
      ALLOWED_SORT_FIELDS = %w[publishedAt receivedAt].freeze

      def initialize(scope, params)
        @scope = scope
        @params = params
        @query = params[:q]
      end

      attr_reader :scope, :params, :query

      def call
        @scope = filter_by_application_type_code
        @scope = filter_by_received_date_range
        @scope = filter_by_validated_date_range
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

      def transform_date_time(date_string)
        return nil if date_string.blank?

        DateTime.strptime(date_string, "%Y/%m/%d").to_time.in_time_zone
      end

      def filter_by_received_date_range
        from = transform_date_time(params[:receivedAtFrom])&.beginning_of_day
        to = transform_date_time(params[:receivedAtTo])&.end_of_day

        return scope if from.nil? || to.nil?

        scope.received_between(from, to)
      end

      def filter_by_validated_date_range
        from = transform_date_time(params[:validatedAtFrom])&.beginning_of_day
        to = transform_date_time(params[:validatedAtTo])&.end_of_day

        return scope if from.nil? || to.nil?

        scope.validated_between(from, to)
      end

      def filter_by_published_date_range
        from = transform_date_time(params[:publishedAtFrom])&.beginning_of_day
        to = transform_date_time(params[:publishedAtTo])&.end_of_day

        return scope if from.nil? || to.nil?

        scope.published_between(from, to)
      end

      def filter_by_consultation_end_date_range
        from = transform_date_time(params[:consultationEndDateFrom])&.beginning_of_day
        to = transform_date_time(params[:consultationEndDateTo])&.end_of_day

        return scope if from.nil? || to.nil?

        scope.consultation_end_between(from, to)
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
