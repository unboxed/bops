# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "bops_api/v2/shared/application", planning_application: @planning_application

json.files @planning_application.documents.for_publication do |document|
  json.name document.name
  json.url main_app.api_v1_planning_application_document_url(@planning_application, document)
  json.extract! document,
    :created_at,
    :applicant_description
end

json.metadata do
  json.results @planning_application.documents.for_publication.count
  json.totalResults @planning_application.documents.for_publication.count
end
