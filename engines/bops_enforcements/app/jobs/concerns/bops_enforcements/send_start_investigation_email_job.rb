# frozen_string_literal: true

module BopsEnforcements
  class SendStartInvestigationEmailJob < NotifyEmailJob
    queue_as :low_priority

    def perform(enforcement)
      client.send_email(
        email_address: enforcement.complainant.email,
        template_id: template_id,
        email_reply_to_id: enforcement.local_authority.email_reply_to_id,
        personalisation: enforcement.start_investigation_email
      )
    end
  end
end
