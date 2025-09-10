# frozen_string_literal: true

# app/jobs/send_test_message_job.rb
class SendTestMessageJob < ApplicationJob
  queue_as :default

  rescue_from Notifications::Client::AuthError do |e|
    with_local_authority { |la| la.update!(notify_error_status: "Your API key is invalid") if e.message.include?("Invalid token") }
    Appsignal.send_exception(e) if defined?(Appsignal)
    raise
  end

  rescue_from Notifications::Client::RequestError do |e|
    Appsignal.send_exception(e) if defined?(Appsignal)
    raise
  end

  def perform(channel:, template_id:, local_authority_id:, email: nil, phone: nil, personalisation: {}, reply_to_id: nil)
    @local_authority_id = local_authority_id
    client = Notifications::Client.new(notify_api_key)

    case channel
    when "email"
      client.send_email(
        email_address: email,
        template_id: template_id,
        personalisation: personalisation,
        email_reply_to_id: reply_to_id
      )
    when "sms"
      client.send_sms(
        phone_number: phone,
        template_id: template_id,
        personalisation: personalisation
      )
    else
      raise ArgumentError, "Unknown channel: #{channel.inspect}"
    end

    with_local_authority { |la| la.update_column(:notify_error_status, nil) if la&.respond_to?(:notify_error_status) }
  end

  private

  def with_local_authority
    la = LocalAuthority.find(@local_authority_id) if @local_authority_id
    yield la if block_given? && la
    la
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def notify_api_key
    with_local_authority { |la| return la.notify_api_key if la&.notify_api_key.present? }
    Rails.configuration.default_notify_api_key.presence ||
      raise("Notify API key not found")
  end
end
