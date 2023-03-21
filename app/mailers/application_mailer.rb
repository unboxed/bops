# frozen_string_literal: true

class ApplicationMailer < Mail::Notify::Mailer
  NOTIFY_TEMPLATE_ID = "7cb31359-e913-4590-a458-3d0cefd0d283"

  private

  def subject(key, args = {})
    I18n.t(key, **args.merge(scope: "emails.subjects"))
  end
end
