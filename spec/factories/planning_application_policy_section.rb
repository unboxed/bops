# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_policy_section do
    association :policy_section
    association :planning_application
  end
end
