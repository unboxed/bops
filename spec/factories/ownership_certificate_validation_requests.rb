# frozen_string_literal: true

FactoryBot.define do
  factory :ownership_certificate_validation_request do
    planning_application { create(:planning_application, :invalidated) }
    user
    state { "open" }
    reason { "Incorrect certificate type" }
    post_validation { false }
    type { "OwnershipCertificateValidationRequest" }

    specific_attributes do
      {
        suggestion: "You need to add more contacts"
      }
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
      response { "Some response" }
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
