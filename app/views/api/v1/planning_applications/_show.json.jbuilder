# frozen_string_literal: true

json.extract! planning_application,
              :id,
              :status,
              :application_type,
              :description,
              :determined_at,
              :target_date,
              :started_at,
              :determined_at,
              :created_at,
              :invalidated_at,
              :withdrawn_at,
              :returned_at,
              :ward,
              :work_status,
              :awaiting_determination_at,
              :in_assessment_at,
              :awaiting_correction_at,
              :agent_first_name,
              :agent_last_name,
              :agent_phone,
              :agent_email,
              :applicant_first_name,
              :applicant_last_name,
              :applicant_email,
              :applicant_phone
json.application_number planning_application.reference
json.site do |site_json|
  site_json.partial! "site.json.jbuilder", site: planning_application.site
end
json.received_date planning_application.created_at
json.decision planning_application.reviewer_decision.status if planning_application.reviewer_decision
json.questions JSON.parse(planning_application.questions) if planning_application.questions
json.constraints JSON.parse(planning_application.constraints) if planning_application.constraints
json.documents planning_application.documents.for_publication do |document|
  json.url api_v1_planning_application_document_url(planning_application, document)
  json.extract! document,
                :created_at,
                :tags,
                :numbers
end
