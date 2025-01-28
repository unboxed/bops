# frozen_string_literal: true

json.decisionNotice do
  json.name "decision-notice-#{planning_application.reference_in_full}.pdf"
  json.url main_app.decision_notice_api_v1_planning_application_url(planning_application, id: planning_application.reference, format: "pdf")
end
