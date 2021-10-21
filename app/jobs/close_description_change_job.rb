# frozen_string_literal: true

class CloseDescriptionJob < ApplicationJob
  queue_as :default

  def self.description_change_requests
    DescriptionChangeValidationRequest.open_change_created_over_5_days_ago
  end

  def perform
    description_change_requests.each do |change_request|
      auto_update_and_notify(change_request)
    end
  end

  def auto_update_and_notify(description_change_request)
    description_change_request.planning_application.update!(description: description_change_request.proposed_description)
    description_change_request.update!(state: "closed", approved: true)
    email_description_closure_notification(description_change_request)
  end

  def email_description_closure_notification(request)
    PlanningApplicationMailer.description_closure_notification_mail(
      request.planning_application,
      request
    ).deliver_now
  end
end
