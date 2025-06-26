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

json.data @planning_applications do |planning_application|
  json.partial! "bops_api/v2/public/shared/show", planning_application: planning_application
  json.partial! "bops_api/v2/shared/postsubmissionApplication/postsubmissionApplication", planning_application: planning_application
end
