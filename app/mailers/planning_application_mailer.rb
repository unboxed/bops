# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  helper :planning_application

  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application, host, user)
    @planning_application = planning_application
    @documents = @planning_application.documents.for_display
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@planning_application.decision}",
      to: user
    )
  end

  def validation_notice_mail(planning_application, host, user)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application has been validated",
      to: user,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def invalidation_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application
    @application_accountable_email = @planning_application.applicant_and_agent_email.first

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application is invalid",
      to: @application_accountable_email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def receipt_notice_mail(planning_application, host, user)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "We have received your application",
      to: user,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def validation_request_mail(planning_application, validation_request)
    build_validation_request_mail(planning_application, validation_request)
  end

  def cancelled_validation_request_mail(planning_application, validation_request)
    build_validation_request_mail(planning_application, validation_request)
  end

  private

  def build_validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request
    @application_accountable_email = @planning_application.applicant_and_agent_email.first

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application at: #{@planning_application.full_address}",
      to: @application_accountable_email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end

  def description_closure_notification_mail(planning_application, description_change_request)
    @planning_application = planning_application
    @description_change_request = description_change_request
    @application_accountable_email = @planning_application.applicant_and_agent_email.first

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application at: #{@planning_application.full_address}",
      to: @application_accountable_email,
      reply_to_id: @planning_application.local_authority.reply_to_notify_id
    )
  end
end
