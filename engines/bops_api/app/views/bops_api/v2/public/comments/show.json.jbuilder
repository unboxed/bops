# frozen_string_literal: true

json.key_format! camelize: :lower


json.partial! "comments", planning_application: @planning_application, comments:

json.metadata do
  json.results @count
  json.totalResults @count
end


