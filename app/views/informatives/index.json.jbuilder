# frozen_string_literal: true

json.array! @informatives do |informative|
  json.title informative.title
  json.text informative.text
end
