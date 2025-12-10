# frozen_string_literal: true

class UserMailer < ApplicationMailer
  def update_notification_mail(planning_application, to)
    @planning_application = planning_application
    @local_authority = planning_application.local_authority
    @reference = planning_application.reference_in_full

    view_mail(email_template_id, headers_for(subject(:update_notification_mail, reference: @reference), to))
  end

  def assigned_notification_mail(planning_application, to)
    @planning_application = planning_application
    @local_authority = planning_application.local_authority
    @reference = planning_application.reference_in_full

    view_mail(email_template_id, headers_for(subject(:assigned_notification_mail, reference: @reference), to))
  end

  def otp_mail(user)
    @local_authority = user.local_authority
    @otp = user.current_otp
    @expiry_minutes = Devise.otp_allowed_drift / 60

    view_mail(email_template_id, headers_for(subject(:otp_mail), user.email))
  end

  private

  attr_reader :local_authority

  delegate :configuration, to: :Rails, prefix: :rails
  delegate :default_notify_api_key, to: :rails_configuration
  delegate :default_email_reply_to_id, to: :rails_configuration
  delegate :default_email_template_id, to: :rails_configuration

  def email_template_id
    local_authority&.email_template_id || default_email_template_id
  end

  def email_reply_to_id
    local_authority&.email_reply_to_id || default_email_reply_to_id
  end

  def notify_api_key
    local_authority&.notify_api_key || default_notify_api_key
  end

  def headers_for(subject, email)
    {
      to: email,
      subject: subject,
      reply_to_id: email_reply_to_id,
      delivery_method: :notify,
      delivery_method_options: {
        api_key: notify_api_key
      }
    }
  end
end
