# frozen_string_literal: true

json.partial! "bops_api/v2/shared/metadata"

json.data @planning_applications do |planning_application|
  json.partial! "bops_api/v2/public/shared/show", planning_application: planning_application
  json.partial! "bops_api/v2/shared/postsubmissionApplication/postsubmissionApplication", planning_application: planning_application
end
