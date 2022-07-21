# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def update_notification_mail(planning_application, to)
    @planning_application = planning_application
    @reference = planning_application.reference_in_full
    subject = subject(:update_notification_mail, reference: @reference)
    view_mail(NOTIFY_TEMPLATE_ID, subject: subject, to: to)
  end
end
