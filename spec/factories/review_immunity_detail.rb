# frozen_string_literal: true

FactoryBot.define do
  factory :review_immunity_detail do
    immunity_detail
    decision { "yes" }
    decision_reason { "it looks immune to me" }
    summary { "they have enough bills to show it's immune" }
  end
end
