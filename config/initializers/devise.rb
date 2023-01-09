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

  config.mailer.class_eval do
    helper :subdomain
  end

  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]

  config.strip_whitespace_keys = [:email]

  config.skip_session_storage = [:http_auth]

  config.stretches = Rails.env.test? ? 1 : 11

  config.reconfirmable = true

  config.expire_all_remember_me_on_sign_out = true

  config.password_length = 8..128

  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  config.reset_password_within = 6.hours

  config.sign_out_via = :delete
end
