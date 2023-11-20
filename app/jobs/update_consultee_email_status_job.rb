# frozen_string_literal: true

class UpdateConsulteeEmailStatusJob < ApplicationJob
  queue_as :low_priority

  NOTIFY_EXCEPTIONS = [
    Notifications::Client::RequestError,
    Timeout::Error,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    EOFError,
    SocketError
  ].freeze

  rescue_from(*NOTIFY_EXCEPTIONS) do
    retry_job wait: 5.minutes
  end

  def perform(consultee_email)
    return if consultee_email.finalized?
    return if consultee_email.email_address.blank?

    # Putting a lock around a network request is normally a bad idea
    # but it prevents a race condition when updating the status.
    consultee_email.with_lock do
      consultee_email.update_status!

      consultee = consultee_email.consultee
      current_time = Time.current

      if consultee_email.delivered?
        consultee.update!(
          status: "awaiting_response",
          email_delivered_at: consultee.email_delivered_at || current_time,
          last_email_delivered_at: current_time
        )
      elsif consultee_email.failed?
        consultee.update!(status: "failed")
      end

      retry_job wait: 5.minutes unless consultee_email.finalized?
    end
  end
end
