# frozen_string_literal: true

class CloseRedLineBoundaryChangeValidationRequestJob < ApplicationJob
  queue_as :low_priority

  def perform
    validation_requests = RedLineBoundaryChangeValidationRequest.open_change_created_over_5_business_days_ago

    # To delete when we've confirmed the scheduled job has run at 9am
    logger.info("\n\n\n***** CloseRedLineBoundaryChangeValidationRequestJob ran at: #{Time.current} *****\n\n\n")

    validation_requests.each do |request|
      request.auto_close_request!

      PlanningApplicationMailer.validation_request_closure_mail(request.planning_application).deliver_now
    end
  end
end
