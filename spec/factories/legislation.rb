# frozen_string_literal: true

FactoryBot.define do
  factory :legislation do
    sequence(:title, 200) { |n| "Town and Country Planning Act 1990, Section #{n}" }

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
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 1, Class A." }
    end

    trait :pa_part_14_class_j do
      title { "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 14, Class J" }
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 14, Class J." }
    end

    trait :pa_part_20_class_ab do
      title { "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 20, Class AB" }
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 20, Class AB." }
    end

    trait :pa_part_3_class_ma do
      title { "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 3, Class MA" }
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 3, Class MA." }
    end

    trait :pa_part7_classM do
      title { "The Town and Country Planning (General Permitted Development) (England) Order 2015 Part 7, Class M" }
      link { "https://www.legislation.gov.uk/uksi/2015/596/schedule/2" }
      description { "Review Condition A.4 of GPDO 2015 (as amended) Schedule 2, Part 7, Class M." }
    end

    trait :tcpa_1990 do
      title { "Town and Country Planning Act 1990" }
      link { "https://www.legislation.gov.uk/ukpga/1990/8" }
    end

    initialize_with { Legislation.find_or_create_by(title:) }
  end
end
