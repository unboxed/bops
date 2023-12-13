# frozen_string_literal: true

json.data @fee_change_validation_requests.each do |fee_change_validation_request|
  json.partial! "show", fee_change_validation_request:
end
