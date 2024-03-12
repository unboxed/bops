# frozen_string_literal: true

json.extract! time_extension_validation_request,
  :id,
  :state,
  :response_due,
  :proposed_expiry_date,
  :reason,
  :rejection_reason,
  :approved,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at
