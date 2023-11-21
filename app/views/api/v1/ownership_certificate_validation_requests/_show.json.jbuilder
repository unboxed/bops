# frozen_string_literal: true

json.extract! ownership_certificate_validation_request,
  :id,
  :state,
  :response_due,
  :approved,
  :rejection_reason,
  :reason,
  :suggestion,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at
