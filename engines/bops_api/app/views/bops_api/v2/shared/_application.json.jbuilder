# frozen_string_literal: true

json.application do
  json.type do
    json.value planning_application.application_type.code
    json.description planning_application.application_type.name
  end
  json.reference planning_application.reference
  json.fullReference planning_application.reference_in_full
  json.receivedAt planning_application.received_at
  json.status planning_application.status
end
