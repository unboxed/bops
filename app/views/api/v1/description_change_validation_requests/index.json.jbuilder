# frozen_string_literal: true

json.data @description_change_validation_requests.each do |description_change_validation_request|
  json.partial! "show", description_change_validation_request:
end
