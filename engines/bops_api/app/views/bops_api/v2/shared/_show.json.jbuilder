# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "bops_api/v2/shared/application", planning_application: planning_application

json.property do
  json.address do
    json.latitude planning_application.latitude
    json.longitude planning_application.longitude
    json.title planning_application.address_1
    json.singleLine planning_application.full_address
    json.uprn planning_application.uprn
    json.town planning_application.town
    json.postcode planning_application.postcode
  end
  json.boundary do
    json.site planning_application.boundary_geojson
  end
end
json.proposal do
  json.description planning_application.description
end
json.applicant do
  json.ownership planning_application.applicant_interest
end
