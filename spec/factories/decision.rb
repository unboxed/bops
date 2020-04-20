# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
  end

  trait :pending do
    status { :pending }
  end

  trait :granted do
    status { :granted }
  end

  trait :refused do
    status { :refused }
  end
end
