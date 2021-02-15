FactoryBot.define do
  factory :recommendation do
    assessor { association :user, :assessor }
    reviewer { nil }
    assessor_comment { "Assessor Comment" }
    reviewer_comment { nil }
    reviewed_at { nil }
  end

  trait :reviewed do
    reviewer { association :user, :reviewer }
    reviewer_comment { "Reviewer Comment" }
    reviewed_at { Time.zone.now }
  end
end
