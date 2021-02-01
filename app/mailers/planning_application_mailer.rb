# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application, host)
    @planning_application = planning_application
    @documents = @planning_application.documents.for_publication
    @host = host

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@planning_application.status}",
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
end
