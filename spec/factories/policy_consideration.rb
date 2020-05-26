# frozen_string_literal: true

FactoryBot.define do
  factory :policy_consideration do
    policy_evaluation
    policy_question { Faker::Lorem.unique.sentence }
    applicant_answer { Faker::Lorem.unique.sentence }
  end
end
