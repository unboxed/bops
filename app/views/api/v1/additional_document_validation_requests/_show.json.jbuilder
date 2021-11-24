# frozen_string_literal: true

json.extract! additional_document_validation_request,
              :id,
              :state,
              :response_due,
              :days_until_response_due,
              :document_request_type,
              :document_request_reason,
              :cancel_reason,
              :cancelled_at

json.new_document do
  if additional_document_validation_request.new_document
    json.name additional_document_validation_request.new_document.file.filename
    json.url additional_document_validation_request.new_document.file.representation(
      resize_to_limit: [1000, 1000]
    ).processed.url
  end
end
