# frozen_string_literal: true

module BopsApi
  class CommentsPublicService
    def initialize(scope, params)
      @scope = scope
      @params = params
    end

    attr_reader :scope, :params

    def call
      paginate(
        sort_results(
          filter_by_query(scope)
        )
      )
    end

    private

    def filter_by_query(scope)
      if params[:query].present?
        scope.where("redacted_response ILIKE ?", "%#{params[:query]}%")
      else
        scope
      end
    end

    def sort_results(scope)
      # Define allowed fields and their default sort orders
      allowed_sort_fields = {
        "receivedAt" => {column: "received_at", default_order: "desc"},
        "id" => {column: "neighbour_responses.id", default_order: "asc"}
      }

      # Define allowed orderBy values
      allowed_order_values = %w[asc desc]

      # Validate sortBy if it is explicitly set
      if params[:sortBy].present?
        sort_by = params[:sortBy]&.camelize(:lower)
        unless allowed_sort_fields.key?(sort_by)
          raise ArgumentError, "Invalid sortBy field: #{params[:sortBy]}. Allowed fields are: #{allowed_sort_fields.keys.join(", ")}"
        end
      else
        sort_by = "receivedAt" # Default sortBy
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
      BopsApi::PostsubmissionPagination.new(scope: scope, params: params).call
    end
  end
end
