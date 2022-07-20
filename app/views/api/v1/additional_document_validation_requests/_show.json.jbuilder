# frozen_string_literal: true

json.extract!(
  additional_document_validation_request,
  :id,
  :state,
  :response_due,
  :days_until_response_due,
  :document_request_type,
  :document_request_reason,
  :cancel_reason,
  :cancelled_at,
  :post_validation
)

json.documents additional_document_validation_request.documents do |document|
  json.name document.file.filename
  json.url document.file.representation(resize_to_limit: [1000, 1000]).processed.url
  json.extract! document
end
