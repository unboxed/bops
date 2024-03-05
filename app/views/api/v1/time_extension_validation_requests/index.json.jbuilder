# frozen_string_literal: true

json.data @time_extension_validation_requests.each do |time_extension_validation_request|
  json.partial! "show", time_extension_validation_request:
end
