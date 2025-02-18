# frozen_string_literal: true

json.array! @requirements do |requirement|
  json.category t(requirement.category, scope: :"requirements.categories")
  json.description requirement.description
  json.guidelines requirement.guidelines
  json.url requirement.url
end
