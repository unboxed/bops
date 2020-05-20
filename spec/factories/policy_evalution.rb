# frozen_string_literal: true

FactoryBot.define do
  factory :policy_evaluation do
    planning_application
    status { :pending }
  end

  trait :met do
    status { :met }
  end

  trait :unmet do
    status { :unmet }
  end

  trait :with_policy_considerations do
    after(:create) do |pe|
      pe.policy_question = Faker::Lorem.unique.sentence
      pe.assessor_answer = Faker::Lorem.unique.sentence
      pe.save!
    end
  end
end
