# frozen_string_literal: true

require "notifications/client"

class NotifyEmailJob < ApplicationJob
  class NotConfiguredError < RuntimeError; end

  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  DELAY_FOR_24_HOURS = [
    Notifications::Client::BadRequestError,
    Notifications::Client::AuthError,
    Notifications::Client::NotFoundError,
    Notifications::Client::ClientError,
    Notifications::Client::RequestError
  ].freeze

  DELAY_FOR_1_HOUR = [
    Notifications::Client::ServerError,
    Timeout::Error,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    EOFError,
    SocketError
  ].freeze

  rescue_from NotifyEmailJob::NotConfiguredError do |exception|
    log_exception(exception)
  end

  # Unexpected error so give us a day to sort things out.
  # If we sort it out before then we can always requeue manually.
  rescue_from(*DELAY_FOR_24_HOURS) do |exception|
    reschedule_job 24.hours.from_now
    Appsignal.send_exception(exception) { |t| t.set_namespace("email") }
  end

  # It's likely that the GOV.UK Notify platform is having problems so
  # delay for an hour to allow them to fix the problem or demand to fall.
  # Don't notify Appsignal because it's likely fix itself.
  rescue_from(*DELAY_FOR_1_HOUR) do |exception|
    reschedule_job 1.hour.from_now
    log_exception(exception)
  end

  # No need to notify Appsignal about these errors as they self heal.
  # If we hit the rate limit just delay for five minutes or if we hit
  # the daily limit delay until the start of the next day when it resets.
  rescue_from(Notifications::Client::RateLimitError) do |exception|
    if exception.message.include?("TooManyRequests")
      reschedule_job Date.tomorrow.beginning_of_day
    else
      reschedule_job 5.minutes.from_now
    end
  end

  # Likely something got deleted so just flag in Appsignal and drop the job.
  rescue_from(ActiveJob::DeserializationError) do |exception|
    Appsignal.send_exception(exception) { |t| t.set_namespace("email") }
  end

  before_perform :set_appsignal_namespace

  private

  def api_key
    Rails.configuration.default_notify_api_key.presence || (raise NotifyEmailJob::NotConfiguredError, "Notify API key not found")
  end

  def client
    @client ||= Notifications::Client.new(api_key)
  end

  def template_id
    NOTIFY_TEMPLATE_ID
  end

  def log_exception(exception)
    logger.info(log_message(exception))
  end

  def log_message(exception)
    "#{exception.class.name} while sending email for #{self.class.name}"
  end

  def set_appsignal_namespace
    Appsignal.set_namespace("email")
  end

  def reschedule_job(time = 1.hour.from_now)
    self.class.set(wait_until: time).perform_later(*arguments)
  end
end
