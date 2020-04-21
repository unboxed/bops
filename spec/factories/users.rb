# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "test#{n}@example.com" }
    name { "Test Assessor" }
    password  { "password123" }
  end

  trait :assessor do
    role { "assessor" }
  end

  trait :reviewer do
    role { "reviewer" }
  end

  trait :admin do
    role { "admin" }
  end
end
