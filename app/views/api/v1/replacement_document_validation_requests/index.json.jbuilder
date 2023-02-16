# frozen_string_literal: true

json.data @replacement_document_validation_requests.each do |replacement_document_validation_request|
  json.partial! "show", replacement_document_validation_request:
end
