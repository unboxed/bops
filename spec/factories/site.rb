# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    uprn { Faker::Base.numerify("00######") }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
  end
end
