# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application do
    site
    agent
    applicant
    sequence(:reference, 10) { |n| "AP/#{4500 + n * 2}/#{n}" }
    description { Faker::Lorem.unique.sentence }
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

    after(:create) do |pa|
      pa.target_date = Date.current + 7.weeks
      pa.save!
    end
  end

  trait :completed do
    status { :completed }

    after(:create) do |pa|
      pa.target_date = Date.current + 1.week
      pa.save!
    end
  end
end
