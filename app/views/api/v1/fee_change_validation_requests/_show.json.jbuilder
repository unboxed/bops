# frozen_string_literal: true

json.extract! fee_change_validation_request,
  :id,
  :state,
  :response_due,
  :response,
  :reason,
  :suggestion,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at
