# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def applicant_and_agent_email(planning_application)
    @agent = planning_application.agent_email
    @applicant = planning_application.applicant_email

    [@agent, @applicant].reject(&:nil?)
  end

  def decision_notice_mail(planning_application, host)
    @planning_application = planning_application
    @documents = @planning_application.documents.for_display
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@planning_application.decision}",
      to: applicant_and_agent_email(@planning_application),
    )
  end

  def validation_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application has been validated",
      to: applicant_and_agent_email(@planning_application),
    )
  end

  def invalidation_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application is invalid",
      to: applicant_and_agent_email(@planning_application),
    )
  end

  def receipt_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "We have received your application",
      to: applicant_and_agent_email(@planning_application),
    )
  end

  def validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request
    @application_accountable_email = @planning_application.agent_email.presence || @planning_application.applicant_email

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application at: #{@planning_application.full_address}",
      to: @application_accountable_email,
    )
  end
end
