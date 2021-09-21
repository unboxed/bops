# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    id { Faker::Name.initials(number: 1) }
    name { Faker::Lorem.sentence }

    after(:build) do |_, klass|
      klass.policies = attributes_for_list(:policy_reference, 3)
    end
  end
end
