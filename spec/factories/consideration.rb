# frozen_string_literal: true

FactoryBot.define do
  factory :consideration do
    policy_area { Faker::Lorem.sentence }
    policy_references {
      [
        {
          code: Faker::IDNumber.unique.ssn_valid,
          description: Faker::Lorem.sentence
        }
      ]
    }
    assessment { Faker::Lorem.paragraph }
    conclusion { Faker::Lorem.sentence }
    advice { Faker::Lorem.paragraph }
    proposal { Faker::Lorem.sentence }

    trait :design_consideration do
      policy_area { "Design" }
      proposal { "Roof lights" }
    end

    consideration_set

    after(:create) do |consideration|
      consideration.consideration_set.update_review(status: "in_progress")
    end
  end
end
