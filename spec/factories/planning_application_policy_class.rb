# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_policy_class do
    association :new_policy_class
    association :planning_application
  end
end
