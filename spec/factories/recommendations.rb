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

  trait :reviewed do
    submitted { true }
    reviewer { association :user, :reviewer }
    reviewer_comment { "Reviewer Comment" }
    reviewed_at { Time.zone.now }
  end
end
