# frozen_string_literal: true

require "notifications/client"

class Consultee < ApplicationRecord
  class Email < ApplicationRecord
    belongs_to :consultee

    delegate :email_address, to: :consultee
    delegate :local_authority, to: :consultee
    delegate :notify_api_key, to: :local_authority, allow_nil: true

    enum :status, {
      pending: "pending",
      created: "created",
      sending: "sending",
      delivered: "delivered",
      permanent_failure: "permanent-failure",
      temporary_failure: "temporary-failure",
      technical_failure: "technical-failure"
    }, scopes: false

    class << self
      def overdue(time = 15.minutes.ago)
        where(status: %w[created sending], status_updated_at: 7.days.ago..time)
      end
    end

    def failed?
      permanent_failure? | temporary_failure? | technical_failure?
    end

    def finalized?
      delivered? || permanent_failure? || technical_failure?
    end

    def update_status!
      return if notify_id.blank?
      return if finalized?

      response = client.get_notification(notify_id)

      update!(
        status: response.status,
        status_updated_at: Time.current
      )
    end

    private

    def client
      @client ||= Notifications::Client.new(api_key)
    end

    def api_key
      notify_api_key.presence || (raise NotifyEmailJob::NotConfiguredError, "Notify API key not found")
    end
  end
end
