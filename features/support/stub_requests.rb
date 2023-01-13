# frozen_string_literal: true

require Rails.root.join "spec/support/api/mapit_helpers"
require Rails.root.join "spec/support/api/paapi_helpers"
require Rails.root.join "spec/support/api/planning_data_helpers"
require Rails.root.join "spec/support/notify_helpers"

World(MapitHelper)
World(PaapiHelper)
World(PlanningDataHelper)
World(NotifyHelper)

Before do
  stub_any_mapit_api_request.to_return(mapit_api_response(:ok))
  stub_paapi_api_request_for("100081043511").to_return(paapi_api_response(:ok))

  stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
  stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
  stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
  stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))

  stub_any_post_sms_notification.to_return(sms_notification_api_response(:ok))
end
