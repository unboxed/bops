# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    origin { "external" }
    category { "consultee" }
    name { Faker::Name.name }
    role { Faker::Job.title }
    organisation { Faker::Company.name }
    email_address { Faker::Internet.safe_email }

    trait :internal do
      origin { "internal" }
    end

    trait :external do
      origin { "external" }
    end
  end
end
