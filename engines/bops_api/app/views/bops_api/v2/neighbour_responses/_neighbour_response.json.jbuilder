# frozen_string_literal: true

json.extract! response,
  :received_at

json.text response.redacted_response.presence
json.sentiment response.summary_tag

json.respondent do
  json.postcode response.neighbour.address.split(/, */).last
end

json.application do
  json.extract! response.neighbour.consultation.planning_application,
    :reference,
    :address
end
