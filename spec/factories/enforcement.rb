# frozen_string_literal: true

FactoryBot.define do
  factory :enforcement do
    association :case_record, strategy: :build
    address_line_1 { Faker::Address.street_address }
    address_line_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
  end
end
