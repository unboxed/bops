# frozen_string_literal: true

json.data @heads_of_terms_validation_requests.each do |heads_of_terms_validation_request|
  json.partial! "show", heads_of_terms_validation_request:
end
