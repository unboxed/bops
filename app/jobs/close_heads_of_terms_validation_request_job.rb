# frozen_string_literal: true

class CloseHeadsOfTermsValidationRequestJob < ApplicationJob
  queue_as :low_priority

  def perform
    heads_of_terms_requets = HeadsOfTermsValidationRequest.open_change_created_over_5_business_days_ago

    heads_of_terms_requets.each do |change_request|
      change_request.auto_close_request!

      PlanningApplicationMailer.description_closure_notification_mail(
        change_request.planning_application,
        change_request
      ).deliver_now
    end
  end
end
