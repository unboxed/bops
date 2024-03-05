# frozen_string_literal: true

json.extract! planning_application,
  :agent_first_name,
  :agent_last_name,
  :agent_phone,
  :agent_email,
  :applicant_first_name,
  :applicant_last_name,
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
if planning_application.site_notices.any?
  json.site_notice_content planning_application.site_notices.order(:created_at).last.content
end
if planning_application.user
  json.assigned_user_name planning_application.user.name
  json.assigned_user_role planning_application.user.role
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
json.decision planning_application.decision if planning_application.determined?
json.constraints planning_application.planning_application_constraints.map(&:constraint).map(&:type_code) if planning_application.planning_application_constraints.any?
json.documents planning_application.documents.for_publication do |document|
  json.url api_v1_planning_application_document_url(planning_application, document)
  json.blob_url url_for(document.blob_url).to_s
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
json.make_public planning_application.make_public
