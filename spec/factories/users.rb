# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    local_authority
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password  { "password123" }
  end

  trait :assessor do
    role { :assessor }
  end

  trait :reviewer do
    role { :reviewer }
  end
end
