# frozen_string_literal: true

json.key_format! camelize: :lower

json.partial! "bops_api/v2/shared/application", planning_application: @planning_application

json.files @documents do |document|
  json.partial! "document", planning_application: @planning_application, document:
end
json.metadata do
  json.results @count
  json.totalResults @count
end

if @planning_application.decision
  json.decisionNotice do
    json.name "decision-notice-#{@planning_application.reference_in_full}.pdf"
    json.url main_app.decision_notice_api_v1_planning_application_url(@planning_application, id: @planning_application.reference, format: "pdf")
  end
end
