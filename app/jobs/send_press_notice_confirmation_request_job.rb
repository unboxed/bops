# frozen_string_literal: true

class SendPressNoticeConfirmationRequestJob < ApplicationJob
  queue_as :low_priority

  def perform(press_notice, user)
    return unless press_notice.required?
    return if press_notice.press_notice_email.blank?

    ApplicationRecord.transaction do
      PlanningApplicationMailer.press_notice_confirmation_request_mail(press_notice, user).deliver_now
    end
  end
end
