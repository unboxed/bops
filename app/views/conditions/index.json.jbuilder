# frozen_string_literal: true

json.array! @conditions do |condition|
  json.title condition.title
  json.text condition.text
  json.reason condition.reason
end
