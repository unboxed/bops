# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  attr_reader :neighbour, :consultation, :letter_content, :resend_reason

  def initialize(neighbour, letter_content, letter_type:, resend_reason: nil, batch: nil)
    @local_authority = neighbour.consultation.planning_application.local_authority
    @neighbour = neighbour
    @consultation = neighbour.consultation
    @letter_content = letter_content
    @resend_reason = resend_reason
    @letter_type = letter_type
    @batch = batch
  end

  def deliver!
    return if resend_reason.nil? && NeighbourLetter.find_by(neighbour:).present? && consultation_letter?

    letter_record = NeighbourLetter.new(neighbour:, text: letter_content, resend_reason:)

    ActiveRecord::Base.transaction do
      letter_record.save!
      consultation.start_deadline if consultation_letter?
    end

    if @batch
      @batch.neighbour_letters << letter_record
    end

    if resend_reason.present?
      letter_content.prepend "# Application updated\nThis application has been updated. Reason: #{resend_reason}\n\n"
    end

    personalisation = {message: letter_content, heading:}
    personalisation.merge! neighbour.format_address_lines

    begin
      response = client.send_letter(
        template_id: @local_authority.letter_template_id,
        personalisation:
      )
    rescue Notifications::Client::RequestError => e
      letter_record.update!(status: "rejected", failure_reason: e.message)
      Appsignal.report_error(e)
      return
    end

    update_letter!(letter_record, response)
    neighbour.touch :last_letter_sent_at
  end

  private

  def heading
    if consultation_letter?
      @consultation.neighbour_letter_header
    else
      @consultation.planning_application.application_type.legislation_title
    end
  end

  def consultation_letter?
    @letter_type == :consultation
  end

  def client
    @client ||= Notifications::Client.new(@local_authority.notify_api_key_for_letters)
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
