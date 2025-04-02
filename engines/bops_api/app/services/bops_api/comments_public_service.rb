# frozen_string_literal: true

module BopsApi
  class CommentsPublicService < CommentsBaseService
    private

    # Defines allowed fields and their default sort orders
    def allowed_sort_fields
      {
        "receivedAt" => {column: "received_at", default_order: "desc"},
        "id" => {column: "neighbour_responses.id", default_order: "asc"}
      }
    end
  end
end
