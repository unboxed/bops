# frozen_string_literal: true

# json.key_format! camelize: :lower


json.key_format! camelize: :lower
json.partial! "bops_api/v2/shared/metadata"

json.data @responses do |response|
  json.partial! "comments", response:
end

