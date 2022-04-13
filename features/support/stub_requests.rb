# frozen_string_literal: true

require Rails.root.join "spec/support/api/mapit_helpers"
require Rails.root.join "spec/support/notify_helpers"

World(MapitHelper)
World(NotifyHelper)

Before do
  stub_any_mapit_api_request.to_return(mapit_api_response(:ok))

  stub_any_post_sms_notification.to_return(sms_notification_api_response(:ok))
end
