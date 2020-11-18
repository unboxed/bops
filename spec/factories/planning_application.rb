# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    site
    agent
    applicant
    local_authority
    description      { Faker::Lorem.unique.sentence }
    status           { :in_assessment }
    in_assessment_at { Time.current }
    ward             { Faker::Address.city }
  end

  trait :lawfulness_certificate do
    application_type { :lawfulness_certificate }
  end

  trait :full do
    application_type { :full }
  end

  trait :awaiting_determination do
    status                    { :awaiting_determination }
    awaiting_determination_at { Time.current }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :awaiting_correction do
    status                    { :awaiting_correction }
    awaiting_determination_at { Time.current }

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :determined do
    status        { :determined }
    determined_at { Time.current }

    after(:create) do |pa|
      pa.target_date = Date.current + 1.week
      pa.save!
    end
  end

  trait :with_policy_evaluation_requirements_unmet do
    after(:create) do |pa|
      create :policy_evaluation,
        status: :unmet,
        planning_application: pa
    end
  end

  trait :with_policy_evaluation_requirements_met do
    after(:create) do |pa|
      create :policy_evaluation,
        status: :met,
        planning_application: pa
    end
  end
end
