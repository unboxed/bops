# frozen_string_literal: true

class PlanningApplicationMailerPreview < ActionMailer::Preview
  def receipt_notice_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.receipt_notice_mail(
      planning_application,
      planning_application.agent_email
    )
  end

  def validation_notice_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.validation_notice_mail(
      planning_application,
      planning_application.agent_email
    )
  end

  def decision_notice_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.decision_notice_mail(
      planning_application,
      "https://www.example.com",
      planning_application.agent_email
    )
  end

  def description_change_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.description_change_mail(
      planning_application,
      planning_application.description_change_validation_requests.last
    )
  end

  def description_closure_notification_mail
    planning_application = PlanningApplication.last

    PlanningApplicationMailer.description_closure_notification_mail(
      planning_application,
      planning_application.description_change_validation_requests.last
    )
  end

  def validation_request_mail
    PlanningApplicationMailer.validation_request_mail(PlanningApplication.last)
  end
end
