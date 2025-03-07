# frozen_string_literal: true

# This contains the structure for the data.appeals section of the Postsubmission Application schema
json.appeal do 
  json.reason planning_application.appeal.reason.camelize(:lower) if planning_application.appeal.reason
  
  json.lodgedDate format_postsubmission_date(planning_application.appeal.lodged_at) if planning_application.appeal.lodged_at
  json.validatedDate format_postsubmission_date(planning_application.appeal.validated_at) if planning_application.appeal.validated_at
  json.startedDate format_postsubmission_date(planning_application.appeal.started_at) if planning_application.appeal.started_at

  json.decisionDate format_postsubmission_date(planning_application.appeal.determined_at) if planning_application.appeal.determined_at 
  json.decision planning_application.appeal.decision if planning_application.appeal.decision

  json.files planning_application.appeal.documents do |document|
    json.partial! "bops_api/v2/shared/document", planning_application: planning_application, document: 
  end if planning_application.appeal.documents

end if planning_application.appeal 
