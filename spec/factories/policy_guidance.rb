# frozen_string_literal: true

FactoryBot.define do
  factory :policy_area do
    policies { "Policy 1, Policy 2" }
    assessment { "The application complies" }
    planning_application
  end
end
