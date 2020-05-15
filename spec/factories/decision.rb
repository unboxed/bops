# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
    granted { true }
  end

  trait :refused do
    granted { false }
  end
end
