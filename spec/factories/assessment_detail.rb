# frozen_string_literal: true

FactoryBot.define do
  factory :assessment_detail do
    planning_application
    user

    category { "summary_of_work" }
    assessment_status { :complete }
    entry { "This is a description about the summary of works" }

    AssessmentDetail.categories.except(:past_applications).each_key do |category|
      trait category do
        category { category }
      end
    end

    trait :past_applications do
      category { :past_applications }
      additional_information { "Additional information" }
    end

    trait :with_consultees do
      planning_application { create(:planning_application, :with_consultees) }
    end
  end
end
