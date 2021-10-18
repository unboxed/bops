# frozen_string_literal: true

FactoryBot.define do
  factory :additional_document_validation_request do
    planning_application
    user
    new_document factory: :document
    state { "open" }
    document_request_type { "Floor plan" }
    document_request_reason { "Missing floor plan" }

    trait :pending do
      state { "pending" }
    end

    trait :open do
      state { "open" }
    end

    trait :closed do
      state { "closed" }
    end

    trait :cancelled do
      state { "cancelled" }
      cancel_reason { "Made by mistake!" }
      cancelled_at { Time.current }
    end
  end
end
