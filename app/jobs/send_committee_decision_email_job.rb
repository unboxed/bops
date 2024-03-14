# frozen_string_literal: true

class SendCommitteeDecisionEmailJob < NotifyEmailJob
  queue_as :low_priority

  def perform(user, planning_application)
    email = user.neighbour_responses.where.not(email: nil).last.email

    client.send_email(
      email_address: email,
      template_id: template_id,
      email_reply_to_id: planning_application.local_authority.email_reply_to_id,
      personalisation: {
        subject: "Notification of Planning Committee Meeting",
        body: planning_application.committee_decision.notification_content
      }
    )
  end
end
