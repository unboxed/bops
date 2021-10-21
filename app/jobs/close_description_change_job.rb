# frozen_string_literal: true

class CloseDescriptionChangeJob < ApplicationJob
  queue_as :default

  def perform
    description_change_requests = DescriptionChangeValidationRequest.open_change_created_over_5_business_days_ago

    description_change_requests.each do |change_request|
      auto_update_and_notify(change_request)

      PlanningApplicationMailer.description_closure_notification_mail(
        change_request.planning_application,
        change_request
      ).deliver_now
    end
  end

  def auto_update_and_notify(description_change_request)
    description_change_request.planning_application.update!(
      description: description_change_request.proposed_description
    )
    description_change_request.approve!
  end
end
