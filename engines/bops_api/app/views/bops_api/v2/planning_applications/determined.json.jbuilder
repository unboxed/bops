# frozen_string_literal: true

json.metadata do
  json.page @pagy.page
  json.results @pagy.limit
  json.from @pagy.from
  json.to @pagy.to
  json.total_pages @pagy.pages
  json.total_results @pagy.count
end

json.data @planning_applications do |planning_application|
  json.partial! "show", planning_application:
end
