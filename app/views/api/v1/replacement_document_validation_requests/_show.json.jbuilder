# frozen_string_literal: true

json.extract! replacement_document_validation_request,
  :id,
  :state,
  :response_due,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at

json.old_document do
  json.name replacement_document_validation_request.old_document.name
  json.invalid_document_reason replacement_document_validation_request.invalidated_document_reason
  json.url replacement_document_validation_request.old_document.representation_url
end

json.new_document do
  if replacement_document_validation_request.new_document
    json.name replacement_document_validation_request.new_document.name
    json.url replacement_document_validation_request.new_document.representation_url
  end
end
