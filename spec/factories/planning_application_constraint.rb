# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_constraint do
    planning_application
    constraint
    planning_application_constraints_query
  end
end
