# frozen_string_literal: true

json.extract! heads_of_terms_validation_request,
  :id,
  :state,
  :cancel_reason,
  :cancelled_at,
  :approved,
  :rejection_reason,
  :owner_id

json.term do
  json.title heads_of_terms_validation_request.owner.title
  json.text heads_of_terms_validation_request.owner.text
  json.heads_of_term_id heads_of_terms_validation_request.owner.heads_of_term_id
end
