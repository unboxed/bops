# frozen_string_literal: true

module ConditionsHelper
  def status(condition)
    if condition.current_validation_request.cancelled?
      "cancelled"
    elsif condition.current_validation_request.approved.nil?
      "awaiting_response"
    elsif condition.current_validation_request.approved?
      if condition.current_validation_request.auto_closed?
        "auto_approved"
      else
        "approved"
      end
    else
      "rejected"
    end
  end
end
