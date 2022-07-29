# frozen_string_literal: true

class UserMailerPreview < ActionMailer::Preview
  def update_notification_mail
    UserMailer.update_notification_mail(
      PlanningApplication.last,
      User.last.email
    )
  end

  def otp_mail
    UserMailer.otp_mail(User.last)
  end
end
