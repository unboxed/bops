# frozen_string_literal: true

FactoryBot.define do
  factory :description_change_validation_request do
    planning_application
    user
    state { "pending" }
    applicant_approved { nil }
    applicant_rejection_reason { nil }
    post_validation { false }

    specific_attributes do
      {
        proposed_description: "New description"
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
