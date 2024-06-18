# frozen_string_literal: true

json.array! @policy_guidances do |policy_guidance|
  json.description policy_guidance.description
  json.url policy_guidance.url
end
