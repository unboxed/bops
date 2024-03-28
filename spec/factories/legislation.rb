# frozen_string_literal: true

FactoryBot.define do
  factory :legislation do
    title { "Town and Country Planning Act 1990, Section #{rand(9999)}" }

    trait :ldc_existing do
      title { "Town and Country Planning Act 1990, Section 191" }
      link { "https://www.legislation.gov.uk/ukpga/1990/8/section/191" }
    end

    trait :ldc_proposed do
      title { "Town and Country Planning Act 1990, Section 192" }
      link { "https://www.legislation.gov.uk/ukpga/1990/8/section/192" }
    end

    trait :pa_part1_classA do
      title { "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 1, Class A" }
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2/made" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 1, Class A." }
    end

    trait :pp_full_householder do
      title { "The Town and Country Planning (Development Management Procedure) (England) Order 2015" }
      link { "https://www.legislation.gov.uk/uksi/2015/595/article/2/made" }
    end
  end
end
