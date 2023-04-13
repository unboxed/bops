# frozen_string_literal: true

class CloseDescriptionChangeJob < ApplicationJob
  queue_as :low_priority

  def perform
    description_change_requests = DescriptionChangeValidationRequest.open_change_created_over_5_business_days_ago

    # To delete when we've confirmed the scheduled job has run at 9am
    logger.info("\n\n\n***** CloseDescriptionChangeJob ran at: #{Time.current} *****\n\n\n")

    description_change_requests.each do |change_request|
      change_request.auto_close_request!

      PlanningApplicationMailer.description_closure_notification_mail(
        change_request.planning_application,
        change_request
      ).deliver_now
    end
  end
end
