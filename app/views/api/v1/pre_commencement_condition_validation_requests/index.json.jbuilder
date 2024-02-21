# frozen_string_literal: true

json.data @pre_commencement_condition_validation_requests.each do |pre_commencement_condition_validation_request|
  json.partial! "show", pre_commencement_condition_validation_request:
end
