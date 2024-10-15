# frozen_string_literal: true

json.partial! "bops_api/v2/shared/metadata"

json.data @validation_requests do |validation_request|
  json.extract! validation_request,
    :type,
    :state,
    :post_validation,
    :created_at,
    :notified_at,
    :reason,
    :response_due,
    :response,
    :rejection_reason,
    :approved,
    :cancel_reason,
    :cancelled_at,
    :closed_at,
    :specific_attributes
end
