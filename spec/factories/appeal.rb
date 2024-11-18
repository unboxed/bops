# frozen_string_literal: true

FactoryBot.define do
  factory :appeal do
    planning_application
    reason { "Applicant disagrees with the decision" }
    status { "lodged" }
    lodged_at { Date.current - 3.days }

    trait :valid do
      status { "validated" }
      validated_at { Date.current - 2.days }
    end

    trait :started do
      status { "started" }
      started_at { Date.current - 1.day }
    end

    trait :determined do
      status { "determined" }
      determined_at { Date.current }
      decision { "allowed" }
    end
  end
end
