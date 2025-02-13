# frozen_string_literal: true

FactoryBot.define do
  factory :policy_section do
    sequence(:section, "1a")
    description { "This is a description of the policy section." }

    association :policy_class
  end
end
