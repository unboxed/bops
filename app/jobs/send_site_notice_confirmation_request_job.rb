# frozen_string_literal: true

class SendSiteNoticeConfirmationRequestJob < ApplicationJob
  queue_as :low_priority

  def perform(site_notice, user)
    return unless site_notice.required?
    return if site_notice.internal_team_email.blank?

    ApplicationRecord.transaction do
      PlanningApplicationMailer.site_notice_confirmation_request_mail(site_notice, user).deliver_now
    end
  end
end
