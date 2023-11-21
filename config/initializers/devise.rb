# frozen_string_literal: true

Devise.setup do |config|
  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :two_factor_authenticatable
  end

  config.sign_in_after_reset_password = false

  config.timeout_in = 6.hours

  config.mailer_sender = "support@unboxed.co"

  config.mailer = "DeviseMailer"

  config.parent_mailer = "ApplicationMailer"

  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]

  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]

  config.stretches = Rails.env.test? ? 1 : 11

  config.reconfirmable = false

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 8..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 3.days

  config.sign_out_via = :delete

  config.otp_allowed_drift = 300
end
