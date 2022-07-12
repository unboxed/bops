# frozen_string_literal: true

class CloseRedLineBoundaryChangeValidationRequestJob < ApplicationJob
  queue_as :default

  def perform
    validation_requests = RedLineBoundaryChangeValidationRequest.open_change_created_over_5_business_days_ago

    validation_requests.each do |request|
      request.auto_close_request!

      PlanningApplicationMailer.validation_request_closure_mail(request.planning_application).deliver_now
    end
  end
end
