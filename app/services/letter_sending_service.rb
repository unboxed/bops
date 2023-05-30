# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  DEFAULT_NOTIFY_TEMPLATE_ID = "701e32b3-2c8c-4c16-9a1b-c883ef6aedee"

  attr_reader :neighbour, :message

  def initialize(neighbour, message)
    @local_authority = neighbour.consultation.planning_application.local_authority
    @neighbour = neighbour
    @message = message
  end

  def deliver!
    letter_record = NeighbourLetter.new(neighbour:, text: message)
    letter_record.save!

    begin
      response = client.send_letter(
        template_id: notify_template_id,
        personalisation: {
          address: neighbour.address,
          message:
        }
      )
    rescue Notifications::Client::RequestError
      return
    end

    letter_record.sent_at = Time.zone.now
    letter_record.notify_response = response
    letter_record.save!
  end

  private

  def client
    @client ||= Notifications::Client.new(notify_api_key)
  end

  def notify_api_key
    @notify_api_key ||= (@local_authority.notify_api_key || ENV.fetch("NOTIFY_API_KEY"))
  end

  def notify_template_id
    @notify_template_id ||= @local_authority.notify_letter_template || DEFAULT_NOTIFY_TEMPLATE_ID
  end
end
