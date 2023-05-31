# frozen_string_literal: true

class NeighbourLetter < ApplicationRecord
  belongs_to :neighbour

  STATUSES = {
    "accepted": "Sent to printer",
    "received": "Dispatched"
  }

  def update_status
    begin
      response = Notifications::Client.new(notify_api_key).get_notification(notify_id)
    rescue Notifications::Client::RequestError
      return
    end

    self.status = response.status
    self.status_updated_at = response.sent_at || response.created_at
    self.save
  end

  def notify_api_key
    notify_api_key ||= (neighbour.consultation.planning_application.local_authority.notify_api_key || ENV.fetch("NOTIFY_API_KEY"))
  end
end
