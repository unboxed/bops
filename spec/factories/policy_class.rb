# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    schedule { "Schedule 1" }
    part { 1 }
    sequence :section, ("A".."G").cycle
    name { Faker::Lorem.sentence }
    url { "https://www.example.com" }
    planning_application

    trait :complies do
      after(:create) do |policy_class|
        create(:policy, :complies, policy_class:)
      end
    end

    trait :in_assessment do
      after(:create) do |policy_class|
        create(:review, status: "in_progress", owner: policy_class)
      end
    end

    trait :complete do
      after(:create) do |policy_class|
        create(:review, status: "complete", owner: policy_class)
      end
    end
  end
end
