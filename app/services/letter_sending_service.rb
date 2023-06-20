# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  DEFAULT_NOTIFY_TEMPLATE_ID = "7a7c541e-be0a-490b-8165-8e44dc9d13ad"

  attr_reader :neighbour, :consultation

  def initialize(neighbour)
    @local_authority = neighbour.consultation.planning_application.local_authority
    @neighbour = neighbour
    @consultation = neighbour.consultation
  end

  def deliver! # rubocop:disable Metrics/AbcSize
    return if NeighbourLetter.find_by(neighbour:).present?

    letter_record = NeighbourLetter.new(neighbour:, text: message)

    ActiveRecord::Base.transaction do
      letter_record.save!
      consultation.update!(end_date: consultation.end_date_from_now, start_date: 1.business_day.from_now)
    end

    personalisation = { message:, heading: "Public consultation" }
    personalisation.merge! address

    begin
      response = client.send_letter(
        template_id: notify_template_id,
        personalisation:
      )
    rescue Notifications::Client::RequestError => e
      letter_record.update(status: "rejected", failure_reason: e.message)
      Appsignal.send_error(e)
      return
    end

    update_letter!(letter_record, response)
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

  def update_letter!(letter_record, response)
    letter_record.tap do |record|
      record.sent_at = Time.zone.now
      record.notify_response = response
      record.notify_id = response.id
      record.status = "accepted"

      record.save!
    end
  end

  def message
    consultation.neighbour_letter_content
  end
end
