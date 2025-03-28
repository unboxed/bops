# frozen_string_literal: true

FactoryBot.define do
  factory :consideration do
    policy_area { Faker::Lorem.sentence }
    policy_references { [{description: Faker::Lorem.sentence}] }
    assessment { Faker::Lorem.paragraph }
    conclusion { Faker::Lorem.sentence }
    advice { Faker::Lorem.paragraph }

    consideration_set

    after(:create) do |consideration|
      consideration.consideration_set.update_review(status: "in_progress")
    end
  end
end
