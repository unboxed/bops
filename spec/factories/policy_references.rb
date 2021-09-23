# frozen_string_literal: true

FactoryBot.define do
  factory :policy_reference, class: Hash do
    id { Faker::Alphanumeric.alpha(number: 3) }
    description { Faker::Lorem.paragraph }

    initialize_with { attributes }
  end
end
