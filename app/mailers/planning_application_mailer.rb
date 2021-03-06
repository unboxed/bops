# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application, host)
    @planning_application = planning_application
    @documents = @planning_application.documents.for_display
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@planning_application.decision}",
      to: @planning_application.applicant_email,
    )
  end

  def validation_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application has been validated",
      to: @planning_application.applicant_email,
    )
  end

  def receipt_notice_mail(planning_application, host)
    @host = host
    @planning_application = planning_application

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "We have received your application",
      to: @planning_application.applicant_email,
    )
  end

  def validation_request_mail(planning_application, validation_request)
    @planning_application = planning_application
    @validation_request = validation_request

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Your planning application at: #{@planning_application.full_address}",
      to: @planning_application.applicant_email,
    )
  end
end
