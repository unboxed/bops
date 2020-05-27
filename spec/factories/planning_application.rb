# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    site
    agent
    applicant
    user
    sequence(:reference, 10) { |n| "AP/#{4500 + n * 2}/#{n}" }
    description { Faker::Lorem.unique.sentence }
    status { :in_assessment }
    ward { Faker::Address.city }
  end

  trait :lawfulness_certificate do
    application_type { :lawfulness_certificate }
  end

  trait :full do
    application_type { :full }
  end

  trait :awaiting_determination do
    status { :awaiting_determination }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :determined do
    status { :determined }

    after(:create) do |pa|
      pa.target_date = Date.current + 1.week
      pa.save!
    end
  end

  trait :with_policy_evaluation_requirements_unmet do
    after(:create) do |pa|
      create :policy_evaluation,
        status: :unmet,
        comment_unmet: "this application is recommended for refusal",
        planning_application: pa
    end
  end

  trait :with_policy_evaluation_requirements_met do
    after(:create) do |pa|
      create :policy_evaluation,
        status: :met,
        comment_met: "this application is recommended for grant",
        planning_application: pa
    end
  end
end
