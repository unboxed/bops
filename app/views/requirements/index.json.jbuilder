# frozen_string_literal: true

json.array! @requirements do |requirement|
  json.description requirement.description
  json.guidelines requirement.guidelines
  json.url requirement.url
end
