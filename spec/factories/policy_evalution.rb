# frozen_string_literal: true

FactoryBot.define do
  factory :policy_evaluation do
    planning_application
    status { :pending }
  end

  trait :met do
    status { :met }
  end

  trait :unmet do
    status { :unmet }
  end
end
