# frozen_string_literal: true

json.data @planning_applications.each do |planning_application|
  json.partial! "show", planning_application:
end
