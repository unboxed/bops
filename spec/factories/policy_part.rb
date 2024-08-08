# frozen_string_literal: true

FactoryBot.define do
  factory :policy_part do
    sequence(:number)
    sequence(:name) { |n| "Part name #{n}" }

    association :policy_schedule
  end
end
