# frozen_string_literal: true

json.array! @application_types do |type|
  json.code type.code
  json.name type.name
  json.suffix type.suffix
end
