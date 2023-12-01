# frozen_string_literal: true

FactoryBot.define do
  factory :replacement_document_validation_request do
    planning_application { create(:planning_application, :invalidated) }
    user
    old_document factory: :document
    reason { "Document is invalid" }
    state { "open" }
    post_validation { false }

    trait :with_response do
      state { "closed" }

      after(:create) do |request|
        create(:document, owner: request)
      end
    end

    trait :pending do
      planning_application { create(:planning_application, :not_started) }

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

    trait :post_validation do
      post_validation { true }
    end
  end
end
