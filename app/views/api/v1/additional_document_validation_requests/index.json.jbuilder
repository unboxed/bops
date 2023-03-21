# frozen_string_literal: true

json.data @additional_document_validation_requests.each do |additional_document_validation_request|
  json.partial! "show", additional_document_validation_request:
end
