# frozen_string_literal: true

FactoryBot.define do
  factory :reporting_type do
    trait :major_dwellings do
      code { "Q01" }
      category { "full" }
      description { "Dwellings (major)" }
    end

    trait :major_offices do
      code { "Q02" }
      category { "full" }
      description { "Offices, R&D, and light industry (major)" }
    end

    trait :major_industry do
      code { "Q03" }
      category { "full" }
      description { "General Industry, storage and warehousing (major)" }
    end

    trait :major_retail do
      code { "Q04" }
      category { "full" }
      description { "Retail and services (major)" }
    end

    trait :householder do
      code { "Q21" }
      category { "householder" }
      description { "Householder developments" }
    end

    trait :ldc do
      code { "Q26" }
      category { "certificate-of-lawfulness" }
      description { "Certificates of lawful development" }
      guidance { "Includes both existing & proposed applications" }
    end

    trait :prior_approval_1a do
      code { "PA1" }
      category { "prior-approval" }
      description { "Larger householder extensions" }
      legislation { "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class A" }
    end
  end
end
