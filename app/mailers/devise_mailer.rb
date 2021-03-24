# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  include Devise::Controllers::UrlHelpers

  def reset_password_instructions(record, token, opts = {})
    initialize_from_record(record)
    opts[:template_id] = "c978a30f-0578-4636-b07e-1e497c3b3893",
    opts[:personalisation] = {
      subject: "Password reset request for: #{record.email}",
    }
    super
  end
end