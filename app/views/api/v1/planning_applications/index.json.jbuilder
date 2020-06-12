# frozen_string_literal: true

json.data @planning_applications.each do |planning_application|
  json.partial! "show.json.jbuilder", planning_application: planning_application
end
