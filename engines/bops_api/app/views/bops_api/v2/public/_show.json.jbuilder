# frozen_string_literal: true

# json.key_format! camelize: :lower

json.application do
  json.type do
    json.value planning_application.application_type.code
    json.description planning_application.application_type.name
  end
  json.reference planning_application.reference
  json.full_reference planning_application.reference_in_full
  json.fullReference planning_application.reference_in_full
  json.received_at planning_application.received_at
  json.receivedAt planning_application.received_at
  json.status planning_application.status
end
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
