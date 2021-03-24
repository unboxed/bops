# frozen_string_literal: true

class UserMailer < Mail::Notify::Mailer
  PASSWORD_RESET_NOTIFY_TEMPLATE_ID = "c978a30f-0578-4636-b07e-1e497c3b3893"

  def reset_password_instructions(record, token, opts = {})
    initialize_from_record(record)
    view_mail(
      PASSWORD_RESET_NOTIFY_TEMPLATE_ID,
      subject: "Password reset request for: #{record.email}",
      to: record.email,
    ).deliver_now
  end
end
