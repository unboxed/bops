# frozen_string_literal: true

FactoryBot.define do
  factory :planx_planning_data do
    planning_application
    entry { "{\"session_id\":\"21161b70-0e29-40e6-9a38-c42f61f25ab9\"}" }
    params_v1 { "{\"application_type\":\"planning_permission\",\"site\":{\"uprn\":\"100081043511\",\"address_1\":\"11 Abbey Gardens\",\"address_2\":\"Southwark\",\"town\":\"London\",\"postcode\":\"SE16 3RQ\",\"latitude\":\"51.4842536\",\"longitude\":\"-0.0764165\"}" }
    session_id { "21161b70-0e29-40e6-9a38-c42f61f25ab9" }
  end
end
