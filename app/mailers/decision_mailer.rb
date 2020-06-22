# frozen_string_literal: true

class DecisionMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  def decision_notice_mail(decision)
    @decision = decision
    @planning_application = decision.planning_application
    @user = decision.planning_application.applicant

    view_mail(
      NOTIFY_TEMPLATE_ID,
      subject: "Certificate of Lawfulness: #{@decision.status}",
      to: @user.email
    )
  end
end
