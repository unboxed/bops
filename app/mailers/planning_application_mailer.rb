# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  helper :planning_application

  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application, host, user)
    @planning_application = planning_application
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:decision_notice_mail),
      to: user
    )
  end

  def validation_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:validation_notice_mail),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def invalidation_notice_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:invalidation_notice_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def receipt_notice_mail(planning_application, email)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:receipt_notice_mail),
      to: email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:validation_request_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def post_validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:post_validation_request_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def cancelled_validation_request_mail(planning_application)
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:cancelled_validation_request_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_change_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:description_change_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_closure_notification_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: subject(:description_closure_notification_mail),
      to: @planning_application.applicant_and_agent_email.first,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  private

  def subject(key)
    I18n.t(key, scope: "planning_applications.emails.subjects")
  end
end
