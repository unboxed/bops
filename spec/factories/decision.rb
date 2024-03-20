# frozen_string_literal: true

FactoryBot.define do
  factory :decision do
    trait :ldc_granted do
      code { "granted" }
      description { "Granted" }
      category { "certificate-of-lawfulness" }
    end

    trait :ldc_refused do
      code { "refused" }
      description { "Refused" }
      category { "certificate-of-lawfulness" }
    end

    trait :pa_granted do
      code { "granted" }
      description { "Prior approval required and approved" }
      category { "prior-approval" }
    end

    trait :pa_not_required do
      code { "not_required" }
      description { "Prior approval not required" }
      category { "prior-approval" }
    end

    trait :pa_refused do
      code { "refused" }
      description { "Prior approval required and refused" }
      category { "prior-approval" }
    end

    trait :full_granted do
      code { "granted" }
      description { "Granted" }
      category { "full" }
    end

    trait :full_refused do
      code { "refused" }
      description { "Refused" }
      category { "full" }
    end

    trait :householder_granted do
      code { "granted" }
      description { "Granted" }
      category { "householder" }
    end

    trait :householder_refused do
      code { "refused" }
      description { "Refused" }
      category { "householder" }
    end
  end
end
