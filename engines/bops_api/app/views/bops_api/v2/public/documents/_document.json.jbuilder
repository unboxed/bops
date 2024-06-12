# frozen_string_literal: true

json.name document.name
json.url main_app.api_v1_planning_application_document_url(@planning_application, document)
json.type document.tags.each do |tag|
  json.value tag
  json.description I18n.t("document_tags.#{tag}")
end
json.extract! document,
  :created_at,
  :applicant_description
json.metadata do
  json.byteSize document.file.byte_size
  json.contentType document.file.content_type
end
