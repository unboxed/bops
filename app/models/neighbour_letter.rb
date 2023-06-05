# frozen_string_literal: true

class NeighbourLetter < ApplicationRecord
  belongs_to :neighbour

  STATUSES = {
    technical_failure: "technical failure",
    permanent_failure: "permanent failure",
    rejected: "rejected",
    submitted: "submitted",
    accepted: "printing",
    received: "posted"
  }.freeze

  def update_status
    begin
      response = Notifications::Client.new(notify_api_key).get_notification(notify_id)
    rescue Notifications::Client::RequestError
      return
    end

    self.status = response.status.parameterize(separator: "_")
    self.status_updated_at = response.sent_at || response.created_at
    save
  end

  def notify_api_key
    neighbour.consultation.planning_application.local_authority.notify_api_key || ENV.fetch("NOTIFY_API_KEY")
  end
end
