# frozen_string_literal: true

module ConditionsHelper
  def status(condition)
    request = condition.current_validation_request

    if request.pending?
      "not_sent"
    elsif request.cancelled?
      "cancelled"
    elsif request.approved.nil?
      "awaiting_response"
    elsif request.approved?
      request.auto_closed? ? "auto_approved" : "approved"
    else
      "rejected"
    end
  end
end
