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
      responses { build_list(:consultee_response, 1) }
    end
  end
end
