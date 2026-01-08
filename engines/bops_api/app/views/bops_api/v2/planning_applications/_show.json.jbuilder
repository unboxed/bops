# frozen_string_literal: true

json.extract! planning_application,
  :agent_first_name,
  :agent_last_name,
  :agent_phone,
  :agent_email,
  :agent_company_name,
  :agent_address_1,
  :agent_address_2,
  :agent_town,
  :agent_county,
  :agent_postcode,
  :applicant_first_name,
  :applicant_last_name,
  :applicant_phone,
  :applicant_email,
  :applicant_address_1,
  :applicant_address_2,
  :applicant_town,
  :applicant_county,
  :applicant_postcode,
  :user_role,
  :awaiting_determination_at,
  :to_be_reviewed_at,
  :created_at,
  :description,
  :determined_at,
  :determination_date,
  :id,
  :invalidated_at,
  :in_assessment_at,
  :payment_reference,
  :payment_amount,
  :alternative_reference,
  :result_flag,
  :result_heading,
  :result_description,
  :result_override,
  :returned_at,
  :started_at,
  :status,
  :target_date,
  :withdrawn_at,
  :work_status,
  :boundary_geojson
if planning_application.user
  json.assigned_user_name planning_application.user.name
  json.assigned_user_role planning_application.user.role
end
if planning_application.applicant_address_1.present?
  json.applicant_address_1 planning_application.applicant_address_1
  json.applicant_address_2 planning_application.applicant_address_2
  json.applicant_town planning_application.applicant_town
  json.applicant_postcode planning_application.applicant_postcode
end
json.applicant_phone planning_application.applicant_phone
json.applicant_email planning_application.applicant_email
if planning_application.ownership_certificate.present?
  json.ownership_certificate planning_application.ownership_certificate.certificate_type
end
json.application_type planning_application.application_type.name
json.reference planning_application.reference
json.reference_in_full planning_application.reference_in_full
json.site do
  json.address_1 planning_application.address_1
  json.address_2 planning_application.address_2
  json.county planning_application.county
  json.town planning_application.town
  json.postcode planning_application.postcode
  json.uprn planning_application.uprn
  json.latitude planning_application.latitude
  json.longitude planning_application.longitude
end
json.received_date planning_application.received_at
json.validAt planning_application.validated_at
json.publishedAt planning_application.published_at
json.decision planning_application.decision if planning_application.determined?
json.constraints planning_application.planning_application_constraints.map(&:constraint).map(&:type_code) if planning_application.planning_application_constraints.any?
json.documents planning_application.documents.active.for_publication do |document|
  json.url main_app.uploaded_file_url(document.blob)
  json.extract! document,
    :created_at,
    :tags,
    :numbers,
    :applicant_description
end
if planning_application.consultation.present?
  json.published_comments planning_application.consultation.neighbour_responses.redacted do |response|
    json.comment response.redacted_response
    json.received_at response.received_at
    json.summary_tag response.summary_tag
  end

  json.consultee_comments planning_application.consultation.consultee_responses.redacted do |response|
    json.comment response.redacted_response
    json.received_at response.received_at
  end

  json.consultation do
    json.end_date planning_application.consultation.end_date
  end
end
json.make_public planning_application.make_public?
