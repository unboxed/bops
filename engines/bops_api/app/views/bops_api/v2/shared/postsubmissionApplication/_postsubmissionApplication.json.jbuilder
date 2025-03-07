# frozen_string_literal: true

# This file is the starting point for building the data in the Postsubmission Application schema
json.data do
  json.partial! "bops_api/v2/shared/postsubmissionApplication/appeal", planning_application: planning_application
end