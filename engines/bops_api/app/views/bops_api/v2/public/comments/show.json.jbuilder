# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "show", consultation: @consultation


json.metadata do
  json.results @count
  json.totalResults @count
end