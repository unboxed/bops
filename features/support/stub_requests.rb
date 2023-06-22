# frozen_string_literal: true

require Rails.root.join "spec/support/api/mapit_helpers"
require Rails.root.join "spec/support/api/paapi_helpers"
require Rails.root.join "spec/support/api/planning_data_helpers"
require Rails.root.join "spec/support/api/plan_x_helpers"
require Rails.root.join "spec/support/notify_helpers"

World(MapitHelper)
World(NotifyHelper)
World(PaapiHelper)
World(PlanningDataHelper)
World(PlanXHelper)

Before do
  stub_any_mapit_api_request.to_return(mapit_api_response(:ok))
  stub_paapi_api_request_for("100081043511").to_return(paapi_api_response(:ok))

  stub_planning_data_api_request_for("BUC").to_return(planning_data_api_response(:ok, "BUC"))
  stub_planning_data_api_request_for("LBH").to_return(planning_data_api_response(:ok, "LBH"))
  stub_planning_data_api_request_for("SWK").to_return(planning_data_api_response(:ok, "SWK"))
  stub_planning_data_api_request_for("TEST").to_return(planning_data_api_response(:ok, "TEST"))

  stub_any_post_sms_notification.to_return(sms_notification_api_response(:ok))

  stub_planx_api_response_for(
    "POLYGON ((-0.054597 51.537331, -0.054588 51.537287, -0.054453 51.537313, -0.054597 51.537331))"
  ).to_return(
    status: 200, body: "{}"
  )
end
