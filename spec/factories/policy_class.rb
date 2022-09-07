# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    schedule { "Schedule 1" }
    part { 1 }
    section { "A" }
    name { Faker::Lorem.sentence }
    url { "https://www.example.com" }
    planning_application
  end
end
