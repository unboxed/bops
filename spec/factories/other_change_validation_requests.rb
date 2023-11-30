# frozen_string_literal: true

FactoryBot.define do
  factory :other_change_validation_request do
    planning_application { create(:planning_application, :invalidated) }
    user
    state { "open" }
    reason { "You need to pay a different fee" }
    post_validation { false }

    specific_attributes do
      {
        suggestion: "Incorrect fee"
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
      applicant_response { "Some response" }
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
