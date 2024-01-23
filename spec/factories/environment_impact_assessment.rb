# frozen_string_literal: true

FactoryBot.define do
  factory :environment_impact_assessment do
    planning_application

    required { true }
  end
end
