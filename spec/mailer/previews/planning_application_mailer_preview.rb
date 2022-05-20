# frozen_string_literal: true

class PlanningApplicationMailerPreview < ActionMailer::Preview
  def receipt_notice_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.receipt_notice_mail(
      planning_application,
      planning_application.agent_email
    )
  end
end
