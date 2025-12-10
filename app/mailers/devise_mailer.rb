# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  attr_reader :user

  delegate :local_authority, to: :user
  delegate :configuration, to: :Rails, prefix: :rails
  delegate :default_notify_api_key, to: :rails_configuration
  delegate :default_email_reply_to_id, to: :rails_configuration
  delegate :default_email_template_id, to: :rails_configuration

  def devise_mail(record, action, opts = {})
    initialize_from_record(record)
    view_mail(email_template_id, headers_for(action, opts).merge(settings))
  end

  private

  def email_template_id
    local_authority&.email_template_id || default_email_template_id
  end

  def email_reply_to_id
    local_authority&.email_reply_to_id || default_email_reply_to_id
  end

  def notify_api_key
    local_authority&.notify_api_key || default_notify_api_key
  end

  def settings
    {
      reply_to_id: email_reply_to_id,
      delivery_method: :notify,
      delivery_method_options: {
        api_key: notify_api_key
      }
    }
  end
end
