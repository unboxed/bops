# frozen_string_literal: true

FactoryBot.define do
  factory :press_notice do
    planning_application

    required { false }

    trait :required do
      required { true }
      reasons do
        {
          environment: "An environmental statement accompanies this application",
          development_plan: "The application does not accord with the provisions of the development plan"
        }
      end
    end

    trait :with_other_reason do
      required { true }
      reasons do
        {
          environment: "An environmental statement accompanies this application",
          other: "An other reason"
        }
      end
    end
  end
end
