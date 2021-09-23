# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    id { "A" }
    name { Faker::Lorem.sentence }

    after(:build) do |_, policy_class|
      policy_class.policies = attributes_for_list(:policy_reference, 3)
    end
  end
end
