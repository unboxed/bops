# frozen_string_literal: true

json.partial! "bops_api/v2/shared/metadata"

json.data @planning_applications do |planning_application|
  json.partial! "show", planning_application:
end
