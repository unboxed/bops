# frozen_string_literal: true

json.pagination do
  json.resultsPerPage @pagy.limit
  json.currentPage @pagy.page
  json.totalPages @pagy.pages
  json.totalItems @pagy.count
end

# json.links pagy_jsonapi_links(@pagy, absolute: true)
