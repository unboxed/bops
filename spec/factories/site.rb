# frozen_string_literal: true

FactoryBot.define do
  factory :site do
    address_1 { "address_1" }
    address_2 { "address_2" }
    town { "town" }
    county { "county" }
    postcode { "postcode" }
  end
end
