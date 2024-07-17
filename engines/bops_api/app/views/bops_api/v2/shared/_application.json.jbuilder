# frozen_string_literal: true

json.application do
  json.type do
    json.value planning_application.application_type.code
    json.description planning_application.application_type.name
  end
  json.reference planning_application.reference
  json.fullReference planning_application.reference_in_full
  json.receivedAt planning_application.received_at
  json.validAt planning_application.validated_at
  json.publishedAt planning_application.published_at
  json.status planning_application.status

  json.determinedAt planning_application.determined_at
  json.decision planning_application.determined? ? planning_application.decision : nil

  if (consultation = planning_application.consultation)
    json.consultation do
      json.startDate consultation.start_date
      json.endDate consultation.end_date
      json.publicLink consultation.application_link
    end
  end
end
