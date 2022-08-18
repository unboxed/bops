# frozen_string_literal: true

FactoryBot.define do
  factory :policy_class do
    id { "A" }
    name { Faker::Lorem.sentence }
    policies { attributes_for_list(:policy_reference, 3) }
  end
end
