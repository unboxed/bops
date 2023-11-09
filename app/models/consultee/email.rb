# frozen_string_literal: true

require "notifications/client"

class Consultee < ApplicationRecord
  class Email < ApplicationRecord
    belongs_to :consultee
    delegate :email_address, to: :consultee

    enum :status, {
      pending: "pending",
      created: "created",
      sending: "sending",
      delivered: "delivered",
      permanent_failure: "permanent-failure",
      temporary_failure: "temporary-failure",
      technical_failure: "technical-failure"
    }, scopes: false

    def failed?
      permanent_failure? | temporary_failure? | technical_failure?
    end

    def finalized?
      delivered? || permanent_failure? || technical_failure?
    end

    def update_status!
      return if notify_id.blank?
      return if finalized?

      begin
        response = client.get_notification(notify_id)
      rescue Notifications::Client::RequestError
        return false
      end

      update!(
        status: response.status,
        status_updated_at: Time.current
      )
    end

    private

    def client
      Notifications::Client.new(api_key)
    end

    def api_key
      consultee.consultation.planning_application.local_authority.notify_api_key || Rails.configuration.default_notify_api_key
    end
  end
end
