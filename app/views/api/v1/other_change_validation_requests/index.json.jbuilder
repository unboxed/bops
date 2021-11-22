# frozen_string_literal: true

json.data @other_change_validation_requests.each do |other_change_validation_request|
  json.partial! "show", other_change_validation_request: other_change_validation_request
end
