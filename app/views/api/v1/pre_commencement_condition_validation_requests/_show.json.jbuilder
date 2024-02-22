# frozen_string_literal: true

json.extract! pre_commencement_condition_validation_request,
  :id,
  :state,
  :response_due,
  :days_until_response_due,
  :cancel_reason,
  :cancelled_at,
  :approved,
  :rejection_reason

json.condition do
  json.title pre_commencement_condition_validation_request.condition.title
  json.text pre_commencement_condition_validation_request.condition.text
  json.reason pre_commencement_condition_validation_request.condition.reason
  json.condition_set_id pre_commencement_condition_validation_request.condition.condition_set.id
end
