# frozen_string_literal: true

FactoryBot.define do
  factory :policy do
    section { "1A" }
    description { Faker::Lorem.paragraph }
    policy_class

    trait :complies do
      status { :complies }
    end

    trait :does_not_comply do
      status { :does_not_comply }
    end

    trait :to_be_determined do
      status { :to_be_determined }
    end
  end
end
