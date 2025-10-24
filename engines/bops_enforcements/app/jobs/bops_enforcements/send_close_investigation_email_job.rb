# frozen_string_literal: true

module BopsEnforcements
  class SendCloseInvestigationEmailJob < NotifyEmailJob
    queue_as :low_priority

    def perform(enforcement, closed_reason:, other_reason:, additional_comment:)
      client.send_email(
        email_address: enforcement.complainant.email,
        template_id: template_id,
        email_reply_to_id: enforcement.local_authority.shared_email_reply_to_id,
        personalisation: EnforcementPresenter.new(enforcement).close_investigation_email(closed_reason:, other_reason:, additional_comment:)
      )
    end
  end
end
