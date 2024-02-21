# frozen_string_literal: true

FactoryBot.define do
  factory :pre_commencement_condition_validation_request do
    planning_application { create(:planning_application, :in_assessment) }
    user
    state { "open" }
    approved { nil }
    post_validation { true }
    condition

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
