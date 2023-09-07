# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    name { "lawfulness_certificate" }

    trait :prior_approval do
      name { "prior_approval" }
    end

    trait :planning_permission do
      name { "planning_permission" }
    end

    initialize_with { ApplicationType.find_or_create_by(name:) }
  end
end
