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
  end
end
