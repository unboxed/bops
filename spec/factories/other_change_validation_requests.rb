# frozen_string_literal: true

FactoryBot.define do
  factory :other_change_validation_request do
    planning_application
    user
    state { "open" }
    summary { "Incorrect fee" }
    suggestion { "You need to pay a different fee" }

    trait :pending do
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
  end
end
