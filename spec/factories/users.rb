# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    email { Faker::Internet.email }
    password  { "password123" }
    local_planning_authority { @local_planning_authority }
  end

  trait :assessor do
    role { :assessor }
  end

  trait :reviewer do
    role { :reviewer }
  end

  trait :admin do
    role { :admin }
  end
end
