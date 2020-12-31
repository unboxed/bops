# frozen_string_literal: true

class PlanningApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(planning_application)
    @planning_application = planning_application
    @decision = @planning_application.reviewer_decision
    @documents = @planning_application.documents.for_publication

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@decision.status}",
      to: @planning_application.applicant_email,
    )
  end
end
