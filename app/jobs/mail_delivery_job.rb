# frozen_string_literal: true

class MailDeliveryJob < ActionMailer::MailDeliveryJob
  include CurrentUserForJob
end
