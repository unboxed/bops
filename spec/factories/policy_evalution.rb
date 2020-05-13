# frozen_string_literal: true

FactoryBot.define do
  factory :policy_evaluation do
    planning_application

    requirements_met { false }
  end
end
