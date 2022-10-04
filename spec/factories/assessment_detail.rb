# frozen_string_literal: true

FactoryBot.define do
  factory :assessment_detail do
    planning_application
    user

    category { "summary_of_work" }
    status { "completed" }
    entry { "This is a description about the summary of works" }

    trait :in_progress do
      status { "in_progress" }
    end

    trait :summary_of_work do
      category { "summary_of_work" }
    end

    trait :additional_evidence do
      category { "additional_evidence" }
    end
  end
end
