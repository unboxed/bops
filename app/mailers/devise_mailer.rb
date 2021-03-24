# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers

  def reset_password_instructions(record, token, opts = {})
    UserMailer.reset_password_instructions(record, token, opts = {})
  end
end