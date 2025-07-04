# frozen_string_literal: true

json.pagination do
  json.resultsPerPage @pagy.limit
  json.currentPage @pagy.page
  json.totalPages @pagy.pages
  json.totalResults @pagy.count
  if @total_available_items.present?
    json.totalAvailableItems @total_available_items
  end
end

# json.links pagy_jsonapi_links(@pagy, absolute: true)
