# frozen_string_literal: true

FactoryBot.define do
  factory :review_immunity_detail do
    immunity_detail
    decision { "Yes" }
    decision_reason { "it looks immune to me" }
    summary { "they have enough bills to show it's immune" }

    trait :accepted do
      accepted { true }
    end

    trait :evidence do
      review_type { "evidence" }
    end
  end
end
