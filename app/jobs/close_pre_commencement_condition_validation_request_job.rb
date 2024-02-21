# frozen_string_literal: true

class ClosePreCommencementConditionValidationRequestJob < ApplicationJob
  queue_as :low_priority

  def perform
    pre_commencement_condition_validation_requests = PreCommencementConditionValidationRequest.open_change_created_over_10_business_days_ago

    pre_commencement_condition_validation_requests.each do |change_request|
      change_request.auto_close_request!

      PlanningApplicationMailer.description_closure_notification_mail(
        change_request.planning_application,
        change_request
      ).deliver_now
    end
  end
end
