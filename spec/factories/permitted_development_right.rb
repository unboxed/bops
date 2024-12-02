# frozen_string_literal: true

FactoryBot.define do
  factory :permitted_development_right do
    planning_application
    assessor { association :user, :assessor }

    status { "not_started" }
    removed { false }

    trait :removed do
      status { "complete" }
      removed { true }
      removed_reason { "Removal reason" }
    end

    trait :checked do
      status { "complete" }
      removed { false }
    end

    trait :in_progress do
      status { "in_progress" }
    end

    trait :to_be_reviewed do
      status { "to_be_reviewed" }
      review_status { "review_complete" }
      removed { true }
      removed_reason { "Removal reason" }
      reviewer { association :user, :reviewer }
      accepted { false }
      reviewer_comment { "Comment" }
      reviewed_at { Time.zone.now }
    end

    trait :accepted do
      status { "complete" }
      review_status { "review_complete" }
      removed { true }
      removed_reason { "Removal reason" }
      reviewer { association :user, :reviewer }
      accepted { true }
      reviewed_at { Time.zone.now }
    end

    trait :review_in_progress do
      status { "complete" }
      review_status { "review_in_progress" }
      removed { false }
      reviewer { association :user, :reviewer }
      accepted { false }
      reviewer_comment { "Comment" }
      reviewed_at { Time.zone.now }
    end
  end
end
