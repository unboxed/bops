# frozen_string_literal: true

FactoryBot.define do
  factory :enforcement_interested_party, class: "Enforcement::InterestedParty" do
    enforcement
    name { Faker::Lorem.name }
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
    relationship { "other" }
    other_relationship { Faker::Lorem.sentence }
  end
end
