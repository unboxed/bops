# frozen_string_literal: true

FactoryBot.define do
  factory :recommendation do
    assessor { association :user, :assessor }
    reviewer { nil }
    assessor_comment { "Assessor Comment" }
    reviewer_comment { nil }
    reviewed_at { nil }
    submitted { nil }
  end

  trait :submitted do
    submitted { true }
  end

  trait :reviewed do
    submitted { true }
    reviewer { association :user, :reviewer }
    reviewer_comment { "Reviewer Comment" }
    reviewed_at { Time.zone.now }
  end

  trait :with_planning_application do
    planning_application
  end

  trait :assessment_in_progress do
    status { :assessment_in_progress }
  end

  trait :assessment_complete do
    status { :assessment_complete }
  end

  trait :review_in_progress do
    status { :review_in_progress }
  end

  trait :review_complete do
    status { :review_complete }
  end
end
