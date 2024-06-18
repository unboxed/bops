# frozen_string_literal: true

json.array! @policy_references do |policy_reference|
  json.code policy_reference.code
  json.description policy_reference.description
  json.url policy_reference.url
end
