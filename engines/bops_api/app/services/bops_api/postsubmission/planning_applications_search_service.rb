# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationsSearchService
      POSTCODE_REGEX = /^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i
      DATE_FIELDS = %i[receivedAt validatedAt publishedAt consultationEndDate].freeze

      def initialize(scope, params)
        @scope = scope
        @params = params
      end
      attr_reader :scope, :params

      def call
        scoped = filter_by(scope)
        scoped = apply_date_filters(scoped)
        scoped = sort_results(scoped)
        paginate(scoped)
      end

      private

      def filter_by(scope)
        status_param = params[:applicationStatus]
        if status_param.present?
          status = Array(status_param)
            .flat_map { |c| c.to_s.split(",") }
            .compact_blank
            .uniq

          scope = scope.where(status:)
        end

        types_param = params[:applicationType]
        if types_param.present?
          codes = Array(types_param)
            .flat_map { |c| c.to_s.split(",") }
            .compact_blank
            .uniq

          scope = scope.for_application_type_codes(codes)
        end

        search_param = (params[:query] || params[:q]).presence
        if search_param.present?
          normalised_query = search_param.downcase.strip

          reference_matches = scope.where(
            "LOWER(reference) LIKE ?",
            "%#{normalised_query}%"
          )
          return reference_matches if reference_matches.exists?

          if normalised_query.match?(POSTCODE_REGEX)
            compacted_postcode = normalised_query.delete(" ")
            postcode_matches = scope.where(
              "LOWER(replace(postcode,' ','')) = ?",
              compacted_postcode
            )
            return postcode_matches if postcode_matches.exists?
          end

          address_query_ts = normalised_query.split.join(" & ")
          address_matches = scope.where(
            "address_search @@ to_tsquery('simple', ?)",
            address_query_ts
          )
          return address_matches if address_matches.exists?

          description_query_ts = normalised_query.split.join(" | ")
          return scope.where(
            "to_tsvector('english', description) @@ to_tsquery('english', ?)",
            description_query_ts
          )
        end

        if params[:reference].present?
          scope = scope.where(
            "LOWER(reference) LIKE ?",
            "%#{params[:reference].downcase}%"
          )
        end

        if params[:description].present?
          scope = scope.where(
            "LOWER(description) LIKE ?",
            "%#{params[:description].downcase}%"
          )
        end

        if params[:postcode].present?
          scope = scope.where(
            "LOWER(postcode) LIKE ?",
            "%#{params[:postcode].downcase}%"
          )
        end

        scope
      end

      def apply_date_filters(current_scope)
        DATE_FIELDS.reduce(current_scope) do |scope, prefix|
          from_key = :"#{prefix}From"
          to_key = :"#{prefix}To"

          if params[from_key].present? || params[to_key].present?
            from_time = parse_date(params[from_key])&.beginning_of_day || Time.zone.at(0)
            to_time = parse_date(params[to_key])&.end_of_day || Time.zone.now.end_of_day

            scope_method = "#{prefix.to_s.underscore}_between"
            scope.public_send(scope_method, from_time, to_time)
          else
            scope
          end
        end
      end

      def parse_date(date_string)
        return if date_string.blank?
        Date.iso8601(date_string)
      rescue ArgumentError
        nil
      end

      def allowed_sort_fields
        {
          "publishedAt" => {column: "published_at", default_order: "desc"},
          "receivedAt" => {column: "received_at", default_order: "desc"}
        }
      end

      def allowed_order_values
        %w[asc desc]
      end

      def default_sort_by
        "publishedAt"
      end

      def sort_results(scope)
        sort_by = params[:sortBy].present? ? params[:sortBy].camelize(:lower) : default_sort_by
        unless allowed_sort_fields.key?(sort_by)
          raise ArgumentError, "Invalid sortBy field: #{params[:sortBy]}"
        end
        order_by = (params[:orderBy].present? && allowed_order_values.include?(params[:orderBy])) ? params[:orderBy] : allowed_sort_fields[sort_by][:default_order]
        scope.reorder("#{allowed_sort_fields[sort_by][:column]} #{order_by}")
      end

      def paginate(scope)
        BopsApi::Postsubmission::PostsubmissionPagination
          .new(scope: scope, params: params)
          .call
      end
    end
  end
end
