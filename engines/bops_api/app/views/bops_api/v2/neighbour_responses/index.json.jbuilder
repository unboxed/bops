# frozen_string_literal: true

json.key_format! camelize: :lower
json.partial! "bops_api/v2/shared/metadata"

json.responses @responses do |response|
  json.partial! "neighbour_response", response:
end
