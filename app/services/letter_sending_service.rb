# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  DEFAULT_NOTIFY_TEMPLATE_ID = "701e32b3-2c8c-4c16-9a1b-c883ef6aedee"

  attr_reader :address, :message

  def initialize(local_authority, address, message)
    @local_authority = local_authority
    @address = address
    @message = message
  end

  def deliver!
    client.send_letter(
      template_id: notify_template_id,
      personalisation: {
        address:,
        message:
      }
    )
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
