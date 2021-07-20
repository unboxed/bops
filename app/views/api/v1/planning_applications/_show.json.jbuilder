# frozen_string_literal: true

json.extract! planning_application,
              :agent_first_name,
              :agent_last_name,
              :agent_phone,
              :agent_email,
              :applicant_first_name,
              :applicant_last_name,
              :application_type,
              :awaiting_determination_at,
              :awaiting_correction_at,
              :created_at,
              :description,
              :determined_at,
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
if planning_application.user
  json.assigned_user_name planning_application.user.name
  json.assigned_user_role planning_application.user.role
end
json.application_number planning_application.reference
json.site do
  json.address_1 planning_application.address_1
  json.address_2 planning_application.address_2
  json.county planning_application.county
  json.town planning_application.town
  json.postcode planning_application.postcode
  json.uprn planning_application.uprn
end
json.received_date planning_application.created_at
json.decision planning_application.decision if planning_application.determined?
json.constraints planning_application.constraints if planning_application.constraints
json.documents planning_application.documents.for_publication do |document|
  json.url api_v1_planning_application_document_url(planning_application, document)
  json.extract! document,
                :created_at,
                :tags,
                :numbers,
                :applicant_description
end
