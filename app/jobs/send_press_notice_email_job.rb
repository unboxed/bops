# frozen_string_literal: true

class SendPressNoticeEmailJob < ApplicationJob
  queue_as :low_priority

  def perform(press_notice, user)
    return unless press_notice.required?
    return if press_notice.press_notice_email.blank?

    ApplicationRecord.transaction do
      PlanningApplicationMailer.press_notice_mail(press_notice).deliver_now

      press_notice.touch(:requested_at)
      press_notice.audits.create!(
        user: user,
        activity_type: "press_notice_mail",
        audit_comment: "Press notice request was sent to #{press_notice.press_notice_email}"
      )
    end
  end
end
