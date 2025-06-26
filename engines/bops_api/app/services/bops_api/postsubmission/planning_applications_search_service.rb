# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class PlanningApplicationsSearchService
      POSTCODE_REGEX = /^(GIR\s?0AA|[A-Z]{1,2}\d[A-Z\d]?\s?\d[A-Z]{2})$/i

      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        paginate(
          sort_results(
            filter_by(scope)
          )
        )
      end

      private

      # Unified three-stage full-text search on 'query' (alias 'q')
      def filter_by(scope)
        raw_q = params[:query].presence
        if raw_q.present?
          q = raw_q.downcase.strip

          ref = scope.where("LOWER(reference) LIKE ?", "%#{q}%")
          return ref if ref.exists?

          if q.match?(POSTCODE_REGEX)
            norm = q.gsub(/\s+/, "")
            pc = scope.where("LOWER(replace(postcode,' ','')) = ?", norm)
            return pc if pc.exists?
          end

          addr_ts = q.split.join(" & ")
          addr = scope.where("address_search @@ to_tsquery('simple', ?)", addr_ts)
          return addr if addr.exists?

          desc_ts = q.split.join(" | ")
          return scope.where(
            "to_tsvector('english', description) @@ to_tsquery('english', ?)",
            desc_ts
          )
        end

        if params[:reference].present?
          scope = scope.where("LOWER(reference) LIKE ?", params[:reference].downcase)
        end

        if params[:description].present?
          scope = scope.where("LOWER(description) LIKE ?", "%#{params[:description].downcase}%")
        end

        if params[:postcode].present?
          scope = scope.where("LOWER(postcode) LIKE ?", "%#{params[:postcode].downcase}%")
        end

        if params[:publishedAtFrom].present? || params[:publishedAtTo].present?
          from = params[:publishedAtFrom].present? ? safe_parse_date(params[:publishedAtFrom]) : nil
          to = params[:publishedAtTo].present? ? safe_parse_date(params[:publishedAtTo]) : nil
          if from || to
            from ||= to
            to ||= from
            scope = scope.where(published_at: from.beginning_of_day..to.end_of_day)
          end
        end

        scope
      end

      def allowed_sort_fields
        {"publishedAt" => {column: "published_at", default_order: "desc"}}
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
        order_by = (params[:orderBy].present? && allowed_order_values.include?(params[:orderBy])) ?
                   params[:orderBy] :
                   allowed_sort_fields[sort_by][:default_order]
        scope.reorder("#{allowed_sort_fields[sort_by][:column]} #{order_by}")
      end

      def paginate(scope)
        BopsApi::Postsubmission::PostsubmissionPagination.new(scope: scope, params: params).call
      end

      def safe_parse_date(str)
        Date.parse(str)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
