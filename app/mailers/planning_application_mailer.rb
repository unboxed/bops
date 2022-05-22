# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  helper :planning_application

  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application, host, user)
    @planning_application = planning_application
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Decision on your Lawful Development Certificate  application",
      to: user
    )
  end

  def validation_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your application for a Lawful Development Certificate",
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def invalidation_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application is invalid",
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def receipt_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Lawful Development Certificate application received",
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Lawful Development Certificate application  - further changes needed",
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def cancelled_validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Update on your application for a Lawful Development Certificate",
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_change_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Lawful Development Certificate application - suggested changes",
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_closure_notification_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Changes to your Lawful Development Certificate application",
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end
end
