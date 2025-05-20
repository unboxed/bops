# frozen_string_literal: true

json.pagination do
  json.resultsPerPage @pagy.limit
  json.currentPage @pagy.page
  json.totalPages @pagy.pages
  json.totalResults @pagy.count
  if @total_responses.present?
    json.totalAvailableItems @total_responses
  end
end

# json.links pagy_jsonapi_links(@pagy, absolute: true)
