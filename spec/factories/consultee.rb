# frozen_string_literal: true

FactoryBot.define do
  factory :consultee do
    name { Faker::Name.name }
    origin { :internal }

    trait :internal do
      origin { :internal }
    end

    trait :external do
      origin { :external }
    end

    trait :with_response do
      response { Faker::Lorem.paragraph }
    end
  end
end
