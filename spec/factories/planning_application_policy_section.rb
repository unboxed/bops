# frozen_string_literal: true

FactoryBot.define do
  factory :planning_application_policy_section do
    association :policy_section
    association :planning_application

    trait :complies do
      status { "complies" }
    end

    trait :does_not_comply do
      status { "does_not_comply" }
    end

    trait :with_comments do
      after(:create) do |planning_application_policy_section|
        create(:comment, text: "A comment", commentable: planning_application_policy_section, commentable_type: "PlanningApplicationPolicySection")
      end
    end

    initialize_with { PlanningApplicationPolicySection.find_or_create_by(planning_application:, policy_section:) }
  end
end
