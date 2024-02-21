# frozen_string_literal: true

Rails.application.config.to_prepare do
  ActionMailer::Base.delivery_job = MailDeliveryJob
end
