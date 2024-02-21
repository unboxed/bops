# frozen_string_literal: true

json.extract! pre_commencement_condition_validation_request,
  :id,
  :state,
  :response_due,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at
