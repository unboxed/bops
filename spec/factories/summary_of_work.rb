# frozen_string_literal: true

FactoryBot.define do
  factory :summary_of_work do
    planning_application
    user

    status { "completed" }
    entry { "This is a description about the summary of works" }

    trait :in_progress do
      status { "in_progress" }
    end
  end
end
