# frozen_string_literal: true

FactoryBot.define do
  factory :press_notice do
    planning_application

    required { false }

    trait :required do
      required { true }
      reasons { %w[environment development_plan] }
      requested_at { Time.zone.now }
    end

    trait :with_other_reason do
      required { true }
      reasons { %w[environment other] }
      other_reason { "An other reason" }
    end
  end
end
