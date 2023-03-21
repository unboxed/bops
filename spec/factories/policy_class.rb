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
      status { :in_assessment }
    end
  end
end
