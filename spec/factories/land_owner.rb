# frozen_string_literal: true

FactoryBot.define do
  factory :land_owner do
    ownership_certificate

    name { "Lauren James" }
    address_1 { "123 street" }
    postcode { "MA1 123" }
    notice_given { true }
    notice_given_at { Time.zone.now }

    trait :not_notified do
      notice_given { false }
      notice_given_at { nil }
    end
  end
end
