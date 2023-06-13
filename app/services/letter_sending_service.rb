# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  DEFAULT_NOTIFY_TEMPLATE_ID = "7a7c541e-be0a-490b-8165-8e44dc9d13ad"

  attr_reader :neighbour, :message

  def initialize(neighbour, message)
    @local_authority = neighbour.consultation.planning_application.local_authority
    @neighbour = neighbour
    @message = message
  end

  def deliver! # rubocop:disable Metrics/AbcSize
    return if NeighbourLetter.find_by(neighbour:).present?

    letter_record = NeighbourLetter.new(neighbour:, text: message)
    letter_record.save!

    personalisation = { message:, heading: neighbour.consultation.planning_application.reference }
    personalisation.merge! address

    begin
      response = client.send_letter(
        template_id: notify_template_id,
        personalisation:
      )
    rescue Notifications::Client::RequestError
      letter_record.update(status: "rejected")
      return
    end

    letter_record.sent_at = Time.zone.now
    letter_record.notify_response = response
    letter_record.notify_id = response.id
    letter_record.status = "accepted"
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

  def address
    # split on commas unless preceded by digits (i.e. house numbers)
    address_lines = neighbour.address.split(/(?<!\d), */).compact
    address_lines.insert(0, "The Occupier")
    address_lines.each_with_index.to_h do |line, i|
      ["address_line_#{i + 1}", line]
    end
  end
end
