# frozen_string_literal: true

FactoryBot.define do
  factory :reporting_type do
    trait :major_dwellings do
      code { "Q01" }
      categories { %w[full] }
      description { "Dwellings (major)" }
    end

    trait :major_offices do
      code { "Q02" }
      categories { %w[full] }
      description { "Offices, R&D, and light industry (major)" }
    end

    trait :major_industry do
      code { "Q03" }
      categories { %w[full] }
      description { "General Industry, storage and warehousing (major)" }
    end

    trait :major_retail do
      code { "Q04" }
      categories { %w[full] }
      description { "Retail and services (major)" }
    end

    trait :householder do
      code { "Q21" }
      categories { %w[householder] }
      description { "Householder developments" }
    end

    trait :ldc do
      code { "Q26" }
      categories { %w[certificate-of-lawfulness] }
      description { "Certificates of lawful development" }
      guidance { "Includes both existing & proposed applications" }
    end

    trait :prior_approval_1a do
      code { "PA1" }
      categories { %w[prior-approval] }
      description { "Larger householder extensions" }
      legislation { "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2, Part 1, Class A" }
    end

    trait :prior_approval_all_others do
      code { "PA99" }
      categories { %w[prior-approval] }
      description { "All others" }
      legislation { "Town and Country Planning (General Permitted Development) (England) Order 2015, Schedule 2" }
    end
  end
end
