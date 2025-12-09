# frozen_string_literal: true

FactoryBot.define do
  factory :enforcement do
    association :case_record, strategy: :build
    address_1 { Faker::Address.street_address }
    address_2 { Faker::Address.secondary_address }
    town { Faker::Address.city }
    county { Faker::Address.state }
    postcode { Faker::Address.postcode }
    description { "Unauthorised erection of a library in the front garden" }

    trait :with_boundary do
      boundary do
        <<~WKT
          GEOMETRYCOLLECTION (
            POLYGON (
              (
                0.506110 51.387327,
                0.506150 51.387279,
                0.506253 51.387315,
                0.506215 51.387360,
                0.506110 51.387327
              )
            )
          )
        WKT
      end
    end

    trait :under_investigation do
      after(:create) { |enforcement| enforcement.start_investigation! }
    end

    trait :closed do
      after(:create) { |enforcement| enforcement.close! }
    end
  end
end
