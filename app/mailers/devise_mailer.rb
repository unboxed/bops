# frozen_string_literal: true

class DeviseMailer < Devise::Mailer
  def devise_mail(record, action, opts = {}, &block)
    initialize_from_record(record)
    view_mail("c978a30f-0578-4636-b07e-1e497c3b3893", headers_for(action, opts))
  end
end
