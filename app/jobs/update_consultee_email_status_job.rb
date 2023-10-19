# frozen_string_literal: true

class UpdateConsulteeEmailStatusJob < ApplicationJob
  queue_as :low_priority

  def perform(consultee_email)
    return if consultee_email.finalized?
    return if consultee_email.email_address.blank?

    # Putting a lock around a network request is normally a bad idea
    # but it prevents a race condition when updating the status.
    consultee_email.with_lock do
      next unless consultee_email.update_status!

      if consultee_email.delivered?
        consultee_email.consultee.update!(
          status: "consulted",
          email_delivered_at: Time.current
        )
      elsif consultee_email.failed?
        consultee_email.consultee.update!(status: "failed")
      end

      retry_job wait: 5.minutes unless consultee_email.finalized?
    end
  end
end
