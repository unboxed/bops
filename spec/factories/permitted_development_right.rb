# frozen_string_literal: true

FactoryBot.define do
  factory :permitted_development_right do
    planning_application

    status { "checked" }
    removed { false }

    trait :removed do
      status { "removed" }
      removed { true }
      removed_reason { "Removal reason" }
    end

    trait :checked do
      status { "checked" }
      removed { false }
    end

    trait :in_progress do
      status { "in_progress" }
    end
  end
end
