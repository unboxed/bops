# frozen_string_literal: true

class ApplicationMailer < Mail::Notify::Mailer
  private

  def subject(key, args = {})
    I18n.t(key, **args.merge(scope: "emails.subjects"))
  end
end
