# frozen_string_literal: true

module MailerHelper
  def request_eia_copy(eia)
    return unless eia.required?

    fee_copy = "for a fee of #{number_to_currency(eia.fee, unit: "£")}"
    email_copy = "by emailing #{eia.email_address}"
    address_copy = "in person at #{eia.address}"
    request_copy = "You can request a hard copy"

    if eia.with_address_email_and_fee?
      "#{request_copy} #{fee_copy} #{email_copy} or #{address_copy}"
    elsif eia.with_address_and_fee?
      "#{request_copy} #{fee_copy} #{address_copy}"
    elsif eia.with_email_and_fee?
      "#{request_copy} #{fee_copy} #{email_copy}"
    end
  end
end
