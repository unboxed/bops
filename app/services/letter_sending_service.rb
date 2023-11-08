# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  DEFAULT_NOTIFY_TEMPLATE_ID = "7a7c541e-be0a-490b-8165-8e44dc9d13ad"

  attr_reader :neighbour, :consultation, :letter_content, :resend_reason

  def initialize(neighbour, letter_content, resend_reason: nil)
    @local_authority = neighbour.consultation.planning_application.local_authority
    @neighbour = neighbour
    @consultation = neighbour.consultation
    @letter_content = letter_content
    @resend_reason = resend_reason
  end

  def deliver!
    return if resend_reason.nil? && NeighbourLetter.find_by(neighbour:).present?

    letter_record = NeighbourLetter.new(neighbour:, text: letter_content, resend_reason:)

    ActiveRecord::Base.transaction do
      letter_record.save!
      consultation.start_deadline
    end

    if resend_reason.present?
      letter_content.prepend "# Application updated\nThis application has been updated. Reason: #{resend_reason}\n\n"
    end

    personalisation = {message: letter_content, heading: @consultation.neighbour_letter_header}
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
    neighbour.touch :last_letter_sent_at
  end

  private

  def client
    @client ||= Notifications::Client.new(notify_api_key)
  end

  def notify_api_key
    if Bops.env.production?
      @notify_api_key ||= (@local_authority.notify_api_key || Rails.configuration.default_notify_api_key)
    else
      @notify_api_key = ENV.fetch("NOTIFY_LETTER_API_KEY")
    end
  end

  def notify_template_id
    if Bops.env.production?
      @notify_template_id ||= @local_authority.notify_letter_template || DEFAULT_NOTIFY_TEMPLATE_ID
    else
      @notify_template_id = DEFAULT_NOTIFY_TEMPLATE_ID
    end
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
end
