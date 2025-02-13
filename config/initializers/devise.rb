# frozen_string_literal: true

Devise.setup do |config|
  config.warden do |manager|
    manager.default_strategies(scope: :user).unshift :two_factor_authenticatable
  end

  config.secret_key = Rails.application.secret_key_base

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

  config.reset_password_within = 6.hours

  config.sign_out_via = [:delete, :get]

  config.otp_allowed_drift = 300

  # ==> Warden configuration

  # Scope the lookup to the local authority when restoring the user from the session
  config.warden do |manager|
    manager.serialize_from_session(:user) do |((id), salt)|
      user = env["bops.user_scope"].find_by(id:)
      user if user && user.authenticatable_salt == salt
    end
  end

  # Reset the token after logging in so that other sessions are logged out
  Warden::Manager.after_set_user except: :fetch do |user, warden, options|
    if warden.authenticated?(:user)
      session = warden.session(:user)
      session["persistence_token"] = user.reset_persistence_token!
    end
  end

  # Logout the user if the token doesn't match what's in the session
  Warden::Manager.after_set_user only: :fetch do |user, warden, options|
    if warden.authenticated?(:user) && options[:store] != false
      session = warden.session(:user)

      unless user.valid_persistence_token?(session["persistence_token"])
        warden.raw_session.clear
        warden.logout(:user)

        throw :warden, scope: :user, message: :other_login
      end
    end
  end

  # Reset the token after logging out
  Warden::Manager.before_logout do |user, warden, options|
    user&.reset_persistence_token!
  end
end
