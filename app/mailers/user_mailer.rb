# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def update_notification_mail(planning_application, to)
    @planning_application = planning_application
    @reference = planning_application.reference_in_full
    subject = subject(:update_notification_mail, reference: @reference)
    view_mail(NOTIFY_TEMPLATE_ID, subject:, to:)
  end

  def assigned_notification_mail(planning_application, to)
    @planning_application = planning_application
    @reference = planning_application.reference_in_full
    subject = subject(:assigned_notification_mail, reference: @reference)
    view_mail(NOTIFY_TEMPLATE_ID, subject:, to:)
  end

  def otp_mail(user)
    @otp = user.current_otp
    @expiry_minutes = Devise.otp_allowed_drift / 60
    view_mail(NOTIFY_TEMPLATE_ID, subject: subject(:otp_mail), to: user.email)
  end
end
