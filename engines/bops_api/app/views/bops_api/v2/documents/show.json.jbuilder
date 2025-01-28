# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "bops_api/v2/shared/application", planning_application: @planning_application

json.files @documents do |document|
  json.partial! "bops_api/v2/shared/document", planning_application: @planning_application, document:
end
json.metadata do
  json.results @count
  json.totalResults @count
end

if @planning_application.decision
  json.partial! "bops_api/v2/shared/decision_notice", planning_application: @planning_application
end
