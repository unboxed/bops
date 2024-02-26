# frozen_string_literal: true

FactoryBot.define do
  factory :heads_of_terms_validation_request do
    planning_application { create(:planning_application, :in_assessment) }
    user
    state { "open" }
    post_validation { true }

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
  end
end
