# frozen_string_literal: true

require "notifications/client"

class LetterSendingService
  attr_reader :consultation, :letter_content, :local_authority, :resend_reason

  def initialize(letter_content, consultation:, letter_type:, resend_reason: nil)
    @consultation = consultation
    @local_authority = consultation.planning_application.local_authority
    @letter_content = letter_content
    @resend_reason = resend_reason
    @letter_type = letter_type
  end

  def deliver!(neighbour)
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
      @letter_content.prepend "# Application updated\nThis application has been updated. Reason: #{resend_reason}\n\n"
    end

    @batch&.update!(text: letter_content)

    return if @local_authority.notify_error_status.present?

    personalisation = {message: letter_content, heading:}
    personalisation.merge! neighbour.format_address_lines

    begin
      response = client.send_letter(
        template_id: local_authority.letter_template_id,
        personalisation:
      )
    rescue Notifications::Client::RequestError => e
      letter_record.update!(status: "rejected", failure_reason: e.message)
      Appsignal.report_error(e)

      case e.message
      when /email_reply_to_id \S+ does not exist/, /email_reply_to_id is not a valid UUID/
        @local_authority.update!(notify_error_status: "bad_email_reply_to_id")
      when /Template not found/
        @local_authority.update!(notify_error_status: "bad_letter_template_id")
      when /Invalid token/, /Cannot send letters with a team api key/, /Can't send to this recipient using a team-only API key/
        @local_authority.update!(notify_error_status: "bad_api_key")
      end

      return
    end

    update_letter!(letter_record, response)
    neighbour.touch :last_letter_sent_at
  end

  def deliver_batch!(neighbours)
    @batch = consultation.neighbour_letter_batches.new(text: letter_content)

    neighbours.each do |neighbour|
      deliver!(neighbour)
    rescue => e
      Appsignal.send_error(e)
      next
    end
  end

  private

  def heading
    if consultation_letter?
      consultation.neighbour_letter_header
    else
      consultation.planning_application.application_type.legislation_title
    end
  end

  def consultation_letter?
    @letter_type == :consultation
  end

  def client
    @client ||= Notifications::Client.new(local_authority.notify_api_key_for_letters)
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
