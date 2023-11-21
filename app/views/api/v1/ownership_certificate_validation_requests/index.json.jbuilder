# frozen_string_literal: true

json.data @ownership_certificate_validation_requests.each do |ownership_certificate_validation_request|
  json.partial! "show", ownership_certificate_validation_request:
end
