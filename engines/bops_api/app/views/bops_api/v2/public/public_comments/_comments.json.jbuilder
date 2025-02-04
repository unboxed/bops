# frozen_string_literal: true

  json.extract! response,
  :received_at

    json.text response.redacted_response.presence
    json.sentiment response.summary_tag
    json.id response.id