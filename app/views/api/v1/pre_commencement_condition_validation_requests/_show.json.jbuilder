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
  json.title pre_commencement_condition_validation_request.owner.title
  json.text pre_commencement_condition_validation_request.owner.text
  json.reason pre_commencement_condition_validation_request.owner.reason
  json.condition_set_id pre_commencement_condition_validation_request.owner.condition_set.id
end
