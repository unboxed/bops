# frozen_string_literal: true

json.extract!(
  additional_document_validation_request,
  :id,
  :state,
  :response_due,
  :days_until_response_due,
  :document_request_type,
  :reason,
  :cancel_reason,
  :cancelled_at,
  :post_validation
)

json.documents additional_document_validation_request.additional_documents do |document|
  json.name document.name
  json.url document.representation_url
  json.extract! document
end
