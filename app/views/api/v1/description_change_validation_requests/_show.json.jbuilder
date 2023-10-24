# frozen_string_literal: true

json.extract! description_change_validation_request,
  :id,
  :state,
  :response_due,
  :proposed_description,
  :previous_description,
  :rejection_reason,
  :approved,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at
