# frozen_string_literal: true

module BopsApi
  module Postsubmission
    class CommentsBaseService
      def initialize(scope, params)
        @scope = scope
        @params = params
      end

      attr_reader :scope, :params

      def call
        scoped = filter_by(scope)
        scoped = sort_results(scoped)
        paginate(scoped)
      end

      private

      # Defines what can be filtered
      def filter_by(scope)
        if params[:query].present?
          scope = scope.where("redacted_response ILIKE ?", "%#{params[:query]}%")
        end

        # Filter by sentiment
        if params[:sentiment].present?
          sentiments = params[:sentiment].map(&:to_s)

          # Validate the provided sentiment values
          allowed_values = allowed_sentiment_values.map(&:keys).flatten
          invalid = sentiments - allowed_values
          if invalid.any?
            raise ArgumentError, "Invalid sentiment(s): #{invalid.join(", ")}. Allowed values: #{allowed_values.join(", ")}"
          end

          # Map to equivalent DB value
          db_sentiments = sentiments.map do |key|
            allowed_sentiment_values.find { |h| h.key?(key) }[key][:value]
          end

          scope = scope.where(summary_tag: db_sentiments)
        end

        scope
      end

      # Defines allowed sentiment values and their corresponding database values
      def allowed_sentiment_values
      end

      # Defines allowed fields and their default sort orders
      def allowed_sort_fields
        {
          "receivedAt" => {column: "received_at", default_order: "desc"}
        }
      end

      # Define allowed orderBy values
      def allowed_order_values
        %w[asc desc]
      end

      # Default sortBy
      def default_sort_by
        "receivedAt"
      end

      # Defines how results are sorted based on the sortBy and orderBy parameters
      def sort_results(scope)
        # Validate sortBy if it is explicitly set
        if params[:sortBy].present?
          sort_by = params[:sortBy]&.camelize(:lower)
          unless allowed_sort_fields.key?(sort_by)
            raise ArgumentError, "Invalid sortBy field: #{params[:sortBy]}. Allowed fields are: #{allowed_sort_fields.keys.join(", ")}"
          end
        else
          sort_by = default_sort_by
        end

        # Validate orderBy if it is explicitly set
        if params[:orderBy].present?
          order_by = params[:orderBy]
          unless allowed_order_values.include?(order_by)
            raise ArgumentError, "Invalid orderBy value: #{params[:orderBy]}. Allowed values are: #{allowed_order_values.join(", ")}"
          end
        else
          order_by = allowed_sort_fields[sort_by][:default_order] # Default orderBy
        end

        # Apply sorting to the scope
        sort_field = allowed_sort_fields[sort_by]
        scope.reorder("#{sort_field[:column]} #{order_by}")
      end

      def paginate(scope)
        BopsApi::Postsubmission::PostsubmissionPagination.new(scope: scope, params: params).call
      end
    end
  end
end
