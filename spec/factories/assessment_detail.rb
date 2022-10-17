# frozen_string_literal: true

FactoryBot.define do
  factory :assessment_detail do
    planning_application
    user

    category { "summary_of_work" }
    status { "completed" }
    entry { "This is a description about the summary of works" }

    AssessmentDetail.categories.each_key do |category|
      trait category do
        category { category }
      end
    end

    trait :with_consultees do
      planning_application { create(:planning_application, :with_consultees) }
    end
  end
end
