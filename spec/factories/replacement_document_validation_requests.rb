# frozen_string_literal: true

FactoryBot.define do
  factory :replacement_document_validation_request do
    planning_application
    user
    old_document factory: :document
    new_document factory: :document
    state { "open" }

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
