# frozen_string_literal: true

FactoryBot.define do
  factory :payment do
    charge
    amount { 50.00 }
    payment_type { "Card" }
    reference { "REF123" }
    payment_date { Time.zone.today }
  end
end
