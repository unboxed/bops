# frozen_string_literal: true

json.key_format! camelize: :lower

json.name document.name
json.references_in_document [document.numbers].compact_blank
json.url main_app.uploaded_file_url(document.blob)
json.type document.tags do |tag|
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
