# frozen_string_literal: true

class SendConsulteeEmailJob < NotifyEmailJob
  queue_as :low_priority

  def perform(consultee_email)
    return if consultee_email.email_address.blank?

    # Putting a lock around a network request is normally a bad idea
    # but it prevents a race condition when updating the status.
    consultee_email.with_lock do
      next unless consultee_email.pending?

      begin
        response = client.send_email(
          email_address: consultee_email.email_address,
          template_id: template_id,
          personalisation: {
            subject: consultee_email.subject,
            body: consultee_email.body
          }
        )

        consultee_email.update!(
          notify_id: response.id,
          status: "created",
          status_updated_at: Time.current,
          sent_at: Time.current
        )

        consultee_email.consultee.update!(
          email_sent_at: Time.current
        )

        UpdateConsulteeEmailStatusJob.set(wait: 1.minute).perform_later(consultee_email)
      rescue Notifications::Client::RequestError => e
        consultee_email.update!(
          status: "technical-failure",
          status_updated_at: Time.current,
          failure_reason: e.message
        )

        Appsignal.send_exception(e) { |t| t.set_namespace("email") }
      end
    end
  end
end
