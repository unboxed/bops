# frozen_string_literal: true

FactoryBot.define do
  factory :review do
    assessor { association :user, :assessor }
    owner { association :policy_class }

    trait :evidence do
      specific_attributes do
        {
          review_type: "evidence",
          decision: "Yes",
          decision_reason: "it looks immune to me",
          summary: "they have enough bills to show it's immune"
        }
      end
    end

    trait :enforcement do
      specific_attributes do
        {
          review_type: "enforcement",
          decision: "Yes",
          decision_reason: "it looks immune to me",
          summary: "they have enough bills to show it's immune"
        }
      end
    end
  end
end
