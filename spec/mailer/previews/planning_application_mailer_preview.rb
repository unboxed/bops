# frozen_string_literal: true

class PlanningApplicationMailerPreview < ActionMailer::Preview
  def cancelled_validation_request_mail
    PlanningApplicationMailer.cancelled_validation_request_mail(
      planning_application
    )
  end

  def decision_notice_mail
    PlanningApplicationMailer.decision_notice_mail(
      planning_application,
      "https://www.example.com",
      planning_application.agent_email
    )
  end

  def description_change_mail
    PlanningApplicationMailer.description_change_mail(
      planning_application,
      planning_application.description_change_validation_requests.last
    )
  end

  def description_closure_notification_mail
    PlanningApplicationMailer.description_closure_notification_mail(
      planning_application,
      planning_application.description_change_validation_requests.last
    )
  end

  def invalidation_notice_mail
    PlanningApplicationMailer.invalidation_notice_mail(planning_application)
  end

  def post_validation_request_mail
    PlanningApplicationMailer.post_validation_request_mail(
      planning_application
    )
  end

  def receipt_notice_mail
    PlanningApplicationMailer.receipt_notice_mail(
      planning_application,
      planning_application.agent_email
    )
  end

  def validation_notice_mail
    PlanningApplicationMailer.validation_notice_mail(
      planning_application,
      planning_application.agent_email
    )
  end

  def validation_request_mail
    PlanningApplicationMailer.validation_request_mail(planning_application)
  end

  private

  def planning_application
    @planning_application ||= PlanningApplication.last
  end
end
