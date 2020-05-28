# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    planning_application
    user
    status { :granted }
  end

  trait :refused do
    status { :refused }
  end
end
