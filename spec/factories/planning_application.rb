# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    site
    agent
    applicant
    reference { "AP/4571/2" }
    submission_date { Date.current }
    description { "description" }
    status { :pending }
  end

  trait :lawfulness_certificate do
    application_type { :lawfulness_certificate }
  end

  trait :full do
    application_type { :full }
  end

  trait :started do
    status { :started }
  end

  trait :completed do
    status { :completed }
  end
end
