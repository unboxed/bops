# frozen_string_literal: true

FactoryBot.define do
  factory :neighbour_response do
    received_at { 1.day.ago }
    response { "I like it rude word" }
    redacted_response { "I like it *****" }
    summary_tag { "supportive" }
    name { "Neighbour" }
    email { "neighbour@example.com" }
    neighbour
    consultation { neighbour.consultation }
  end

  trait :objection do
    summary_tag { "objection" }
    response { "I hate it rude word" }
    redacted_response { "I hate it [redacted]" }
  end

  trait :without_redaction do
    redacted_response { nil }
  end
end
