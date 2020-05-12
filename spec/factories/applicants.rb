# frozen_string_literal: true

FactoryBot.define do
  factory :applicant do
    agent
    first_name { Faker::Name.unique.first_name }
    last_name { Faker::Name.unique.last_name }
    phone { Faker::Base.numerify("+44 7### ######") }
    email { Faker::Internet.email }
    postcode { Faker::Address.postcode }
    address_1 { Faker::Address.street_address }
    town { "London" }
    residence_status { false }
  end
end
