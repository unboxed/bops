# frozen_string_literal: true

FactoryBot.define do
  factory :application_type do
    name { "lawfulness_certificate" }

    trait :prior_approval do
      name { "prior_approval" }
    end
  end
end
