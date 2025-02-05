# frozen_string_literal: true

FactoryBot.define do
  factory :additional_service do
    planning_application

    trait :with_meeting do
      name { "meeting" }
    end
  end
end
